import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';

class AddLeadSheet extends ConsumerStatefulWidget {
  const AddLeadSheet({super.key, this.fromListing});

  final Listing? fromListing;

  @override
  ConsumerState<AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends ConsumerState<AddLeadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  LeadStage _stage = LeadStage.newLead;
  LeadPriority _priority = LeadPriority.medium;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    if (widget.fromListing != null) {
      _valueCtrl.text = widget.fromListing!.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _valueCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final listing = widget.fromListing;
    final success = await ref.read(crmProvider.notifier).createLead(
          clientName: _nameCtrl.text.trim(),
          stage: _stage,
          priority: _priority,
          clientPhone:
              _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          estimatedValue: double.tryParse(
            _valueCtrl.text.replaceAll(',', ''),
          ),
          linkedListingId: listing?.id,
          linkedListingCity: listing?.city,
          linkedListingPrice: listing?.priceLabel,
          linkedListingImageUrl: listing?.heroImageUrl,
          remarks: _remarksCtrl.text.trim().isEmpty
              ? null
              : _remarksCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).leadAddedToPipeline),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(crmProvider).error;
      setState(
          () => _saveError = err ?? 'Failed to save lead. Please try again.',);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyMid : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle + header
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(

                        Icons.person_add_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).addLead,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                // Linked listing banner
                if (widget.fromListing != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.fromListing!.location}, '
                            '${widget.fromListing!.city} · '
                            '${widget.fromListing!.priceLabel}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Section: Contact ─────────────────────────────────────
                _SectionLabel('Contact', isDark: isDark),
                const SizedBox(height: 10),

                // Client name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.of(context).nameRequired
                      : null,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).clientName,
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section: Interest ────────────────────────────────────
                _SectionLabel('Interest', isDark: isDark),
                const SizedBox(height: 10),

                // Remarks
                TextFormField(
                  controller: _remarksCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    hintText: 'e.g. Looking for 3BHK under ₹75L, prefers south-facing',
                    prefixIcon: Icon(Icons.format_quote_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Estimated value
                TextFormField(
                  controller: _valueCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Budget / Est. Value',
                    hintText: '7500000',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section: Pipeline ────────────────────────────────────
                _SectionLabel('Pipeline', isDark: isDark),
                const SizedBox(height: 10),

                // Stage selector
                _StageSelector(
                  label: AppLocalizations.of(context).stageLabel,
                  selected: _stage,
                  onSelect: (s) => setState(() => _stage = s),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Priority selector
                _PrioritySelector(
                  label: AppLocalizations.of(context).priorityLabel,
                  selected: _priority,
                  onSelect: (p) => setState(() => _priority = p),
                  isDark: isDark,
                ),

                const SizedBox(height: 24),

                if (_saveError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10,),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16,),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _saveError!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyDark,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context).addToPipelineBtn,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.navyDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _StageSelector extends StatelessWidget {
  const _StageSelector({
    required this.label,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  final String label;
  final LeadStage selected;
  final ValueChanged<LeadStage> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: LeadStage.values.map((s) {
            final isSelected = selected == s;
            return GestureDetector(
              onTap: () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? s.color.withValues(alpha: 0.15)
                      : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? s.color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  s.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? s.color : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.label,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  final String label;
  final LeadPriority selected;
  final ValueChanged<LeadPriority> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: LeadPriority.values.map((p) {
            final isSelected = selected == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: EdgeInsets.only(
                    right: p != LeadPriority.high ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? p.color.withValues(alpha: 0.15)
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.offWhite),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? p.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          p.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? p.color
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
