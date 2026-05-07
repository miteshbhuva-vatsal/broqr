import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cpapp/core/constants/indian_cities.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// First-login sheet: detect city via GPS or pick manually.
/// Dismissing without selection calls [CityPreferenceNotifier.skip].
class CitySelectionSheet extends ConsumerStatefulWidget {
  const CitySelectionSheet({super.key});

  @override
  ConsumerState<CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _CitySelectionSheetState extends ConsumerState<CitySelectionSheet> {
  final _search = TextEditingController();
  List<String> _filtered = IndianCities.all;
  bool _detecting = false;
  String? _detectedCity;
  String? _gpsError;

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

  Future<void> _detectGps() async {
    // Capture localized strings before any async gap
    final l = AppLocalizations.of(context);
    final permMsg = l.gpsPermissionDenied;
    final unknownMsg = l.couldNotDetermineCity;
    final unavailMsg = l.gpsUnavailable;

    setState(() {
      _detecting = true;
      _gpsError = null;
      _detectedCity = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = permMsg;
          _detecting = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final raw = placemarks.isNotEmpty
          ? (placemarks.first.locality?.trim() ?? '')
          : '';

      if (raw.isEmpty) {
        setState(() {
          _gpsError = unknownMsg;
          _detecting = false;
        });
        return;
      }

      // Try to match against known list (case-insensitive)
      final match = IndianCities.all.firstWhere(
        (c) => c.toLowerCase() == raw.toLowerCase(),
        orElse: () => raw,
      );

      setState(() {
        _detectedCity = match;
        _detecting = false;
      });
    } catch (_) {
      setState(() {
        _gpsError = unavailMsg;
        _detecting = false;
      });
    }
  }

  Future<void> _selectCity(String city) async {
    await ref.read(cityPreferenceProvider.notifier).setCity(city);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    await ref.read(cityPreferenceProvider.notifier).skip();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyMid : AppColors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).yourCity,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your city to see relevant deals in your area.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GPS detect button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _detecting ? null : _detectGps,
                        icon: _detecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded,
                                color: AppColors.gold, size: 18,),
                        label: Text(
                          _detecting ? '…' : AppLocalizations.of(context).detectViaGps,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_detectedCity != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectCity(_detectedCity!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12,),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.gold, size: 18,),
                              const SizedBox(width: 8),
                              Text(
                                _detectedCity!,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.navyDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                AppLocalizations.of(context).useThisCity,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_gpsError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _gpsError!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        AppLocalizations.of(context).orSearch.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textHint,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search city…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
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
              const SizedBox(height: 4),
              const Divider(height: 1),

              // City list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).noCitiesFound,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final city = _filtered[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_city_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            title: Text(
                              city,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            onTap: () => _selectCity(city),
                          );
                        },
                      ),
              ),

              // Skip
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppLocalizations.of(context).skipForNow,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
