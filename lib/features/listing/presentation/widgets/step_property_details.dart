import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart' show AreaUnit, ListingVisibility;
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/profile/presentation/widgets/city_picker_sheet.dart';

/// Step 2 — Property details form (city, location, area, price, description).
class StepPropertyDetails extends StatefulWidget {
  const StepPropertyDetails({
    super.key,
    required this.category,
    required this.title,
    required this.city,
    required this.location,
    required this.area,
    required this.price,
    required this.originalPrice,
    required this.brokerage,
    required this.description,
    required this.onTitleChanged,
    required this.onCityChanged,
    required this.onLocationChanged,
    required this.onAreaChanged,
    required this.onPriceChanged,
    required this.onOriginalPriceChanged,
    required this.onBrokerageChanged,
    required this.onDescriptionChanged,
    required this.visibility,
    required this.onVisibilityChanged,
    required this.areaUnit,
    required this.onAreaUnitChanged,
    this.propertyType,
    this.onPropertyTypeChanged,
    this.formKey,
  });

  final ListingCategory category;
  final PropertyType? propertyType;
  final String title;
  final String city;
  final String location;
  final String area;
  final String price;
  final String originalPrice;
  final String brokerage;
  final String description;
  final AreaUnit areaUnit;
  final ValueChanged<AreaUnit> onAreaUnitChanged;
  final ListingVisibility visibility;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onAreaChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onOriginalPriceChanged;
  final ValueChanged<String> onBrokerageChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<ListingVisibility> onVisibilityChanged;
  final ValueChanged<PropertyType?>? onPropertyTypeChanged;
  final GlobalKey<FormState>? formKey;

  @override
  State<StepPropertyDetails> createState() => _StepPropertyDetailsState();
}

class _StepPropertyDetailsState extends State<StepPropertyDetails> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _brokerageCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.title);
    _locationCtrl = TextEditingController(text: widget.location);
    _areaCtrl = TextEditingController(text: widget.area);
    _priceCtrl = TextEditingController(text: widget.price);
    _originalPriceCtrl = TextEditingController(text: widget.originalPrice);
    _brokerageCtrl = TextEditingController(text: widget.brokerage);
    _descCtrl = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _areaCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _brokerageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet(selected: widget.city),
    );
    if (city != null) widget.onCityChanged(city);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.category.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.category.color.withValues(alpha: 0.3),),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.category.emoji,
                        style: const TextStyle(fontSize: 13),),
                    const SizedBox(width: 5),
                    Text(
                      widget.category.localizedLabel(Localizations.localeOf(context).languageCode),
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.category.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l.propertyDetails,
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.white : AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.fillDetailsDesc,
            style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,),
          ),
          const SizedBox(height: 24),

          // Project / Scheme title (optional)
          _Label(l.projectSchemeName, required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            onChanged: widget.onTitleChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g. Lodha Palava, DDA Scheme 2025',
              prefixIcon: Icon(Icons.apartment_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // City picker
          _Label(l.cityRequired, required: true),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickCity,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city_outlined,
                      size: 20, color: AppColors.textSecondary,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.city.isEmpty ? l.selectCityHint : widget.city,
                      style: AppTypography.bodyMedium.copyWith(
                        color: widget.city.isEmpty
                            ? AppColors.textHint
                            : (isDark
                                ? AppColors.white
                                : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Property type
          _Label(l.propertyType, required: false),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PropertyType.values.map((pt) {
              final selected = widget.propertyType == pt;
              return GestureDetector(
                onTap: () => widget.onPropertyTypeChanged?.call(
                  selected ? null : pt,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.gold
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.gold
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.border),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pt.emoji,
                          style: const TextStyle(fontSize: 12),),
                      const SizedBox(width: 5),
                      Text(
                        pt.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.navyDark
                              : (isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Location / Society name
          _Label(l.locationSociety, required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _locationCtrl,
            onChanged: widget.onLocationChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.locationRequired : null,
            decoration: const InputDecoration(
              hintText: 'e.g. Andheri West, Oberoi Springs',
              prefixIcon:
                  Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Area — number field + unit picker
          _Label(l.area, required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _areaCtrl,
            onChanged: widget.onAreaChanged,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.areaRequired : null,
            decoration: const InputDecoration(
              hintText: '1200',
              prefixIcon: Icon(Icons.straighten_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: AreaUnit.values.map((u) {
              final selected = widget.areaUnit == u;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onAreaUnitChanged(u),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                      right: u != AreaUnit.values.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.gold
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        u.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.navyDark
                              : (isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Price pair — MRP + Deal price side by side
          _PricePairHint(isDark: isDark),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MRP / market price (optional — shows strikethrough)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(l.marketPriceMrp, required: false),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _originalPriceCtrl,
                      onChanged: widget.onOriginalPriceChanged,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '9000000',
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                        helperText: l.optionalLabel,
                        helperStyle: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Actual deal / asking price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(l.dealPrice, required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceCtrl,
                      onChanged: widget.onPriceChanged,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.requiredLabel
                          : null,
                      decoration: InputDecoration(
                        hintText: '7500000',
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                        helperText: l.askingPrice,
                        helperStyle: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brokerage (optional)
          _Label(l.brokerage, required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _brokerageCtrl,
            onChanged: widget.onBrokerageChanged,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g. 2% or ₹50,000',
              prefixIcon: Icon(Icons.handshake_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Description (optional)
          _Label(l.description, required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl,
            onChanged: widget.onDescriptionChanged,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.descriptionHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Visibility picker
          _Label(l.whoCanSee, required: false),
          const SizedBox(height: 10),
          _VisibilityPicker(
            selected: widget.visibility,
            onChanged: widget.onVisibilityChanged,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            widget.visibility.description,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePairHint extends StatelessWidget {
  const _PricePairHint({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.priceStrikethroughHint,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,),),
      ],
    );
  }
}

class _VisibilityPicker extends StatelessWidget {
  const _VisibilityPicker({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  final ListingVisibility selected;
  final ValueChanged<ListingVisibility> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ListingVisibility.values.map((v) {
        final isSelected = selected == v;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: v != ListingVisibility.values.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : (isDark ? AppColors.borderDark : AppColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    v.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.navyDark
                          : (isDark ? AppColors.white : AppColors.textPrimary),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
