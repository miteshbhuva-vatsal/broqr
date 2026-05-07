import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';

/// Bottom sheet for creating a new lead, optionally pre-filled from a [Listing].
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

  LeadStage _stage = LeadStage.newLead;
  LeadPriority _priority = LeadPriority.medium;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromListing != null) {
      final l = widget.fromListing!;
      _valueCtrl.text = l.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final listing = widget.fromListing;
    final success = await ref.read(crmProvider.notifier).createLead(
          clientName: _nameCtrl.text.trim(),
          stage: _stage,
          priority: _priority,
          clientPhone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          estimatedValue: double.tryParse(
            _valueCtrl.text.replaceAll(',', ''),
          ),
          linkedListingId: listing?.id,
          linkedListingCity: listing?.city,
          linkedListingPrice: listing?.priceLabel,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).leadAddedToPipeline),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context).addLead,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.white : AppColors.navyDark,
                  ),
                ),

                // Linked listing banner
                if (widget.fromListing != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 16, color: AppColors.gold,),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'From listing: '
                            '${widget.fromListing!.location}, '
                            '${widget.fromListing!.city} · '
                            '${widget.fromListing!.priceLabel}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gold,
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

                // Client name
                _Label(AppLocalizations.of(context).clientName, required: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.of(context).nameRequired
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone
                _Label(AppLocalizations.of(context).phoneLabel, required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                ),
                const SizedBox(height: 14),

                // Estimated value
                _Label(AppLocalizations.of(context).estimatedValue, required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _valueCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '7500000',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Stage selector
                _Label(AppLocalizations.of(context).stageLabel, required: true),
                const SizedBox(height: 8),
                _StageSelector(
                  selected: _stage,
                  onSelect: (s) => setState(() => _stage = s),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Priority selector
                _Label(AppLocalizations.of(context).priorityLabel, required: true),
                const SizedBox(height: 8),
                _PrioritySelector(
                  selected: _priority,
                  onSelect: (p) => setState(() => _priority = p),
                  isDark: isDark,
                ),
                const SizedBox(height: 28),

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
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        : Text(
                            AppLocalizations.of(context).addToPipelineBtn,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w700,
                            ),
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

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _StageSelector extends StatelessWidget {
  const _StageSelector({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  final LeadStage selected;
  final ValueChanged<LeadStage> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LeadStage.values.map((s) {
        final isSelected = selected == s;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? s.color.withValues(alpha: 0.15)
                  : (isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(20),
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
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  final LeadPriority selected;
  final ValueChanged<LeadPriority> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LeadPriority.values.map((p) {
        final isSelected = selected == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: p != LeadPriority.high ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? p.color.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(10),
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
                        color:
                            isSelected ? p.color : AppColors.textSecondary,
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
    );
  }
}
