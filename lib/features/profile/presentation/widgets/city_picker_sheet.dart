import 'package:flutter/material.dart';
import 'package:cpapp/core/constants/indian_cities.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// Modal bottom sheet with a searchable list of Indian cities.
/// Returns the selected city string via [Navigator.pop].
class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key, this.selected});
  final String? selected;

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final _search = TextEditingController();
  List<String> _filtered = IndianCities.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = IndianCities.all
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Material(
      color: isDark ? AppColors.navyMid : AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(l.selectCityTitle,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: l.searchCityHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              const Divider(height: 1),

              // City list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(l.noCitiesFound,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final city = _filtered[i];
                          final isSelected = city == widget.selected;
                          return ListTile(
                            title: Text(
                              city,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.gold
                                    : (isDark
                                        ? AppColors.white
                                        : AppColors.textPrimary),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: AppColors.gold, size: 20,)
                                : null,
                            onTap: () => Navigator.pop(context, city),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
