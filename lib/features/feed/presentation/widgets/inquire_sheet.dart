import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/presentation/widgets/add_lead_sheet.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';

/// Bottom sheet shown when a user taps "Inquire" on a feed card.
class InquireSheet extends StatelessWidget {
  const InquireSheet({super.key, required this.listing});

  final Listing listing;

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = listing.brokerPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final text = Uri.encodeComponent(
      'Hi ${listing.brokerName}, I saw your ${listing.category.label} '
      'listing on CPApp — ${listing.location}, ${listing.city} '
      '(${listing.priceLabel}). I\'m interested, please share more details.',
    );
    final uri = Uri.parse('https://wa.me/91$phone?text=$text');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhone =
        listing.brokerPhone != null && listing.brokerPhone!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
          const SizedBox(height: 20),

          // Listing summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: listing.category.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      listing.category.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.priceLabel,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${listing.location}, ${listing.city}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        listing.category.localizedLabel(Localizations.localeOf(context).languageCode),
                        style: AppTypography.labelSmall.copyWith(
                          color: listing.category.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppLocalizations.of(context).contactBroker,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            listing.brokerName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // WhatsApp button
          _SheetButton(
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            label: hasPhone
                ? AppLocalizations.of(context).messageOnWhatsApp
                : 'WhatsApp (phone not listed)',
            sublabel: hasPhone ? listing.brokerPhone! : AppLocalizations.of(context).noBrokerPhone,
            enabled: hasPhone,
            onTap: hasPhone ? () => _openWhatsApp(context) : null,
          ),
          const SizedBox(height: 10),

          // Save as lead → opens AddLeadSheet pre-filled from this listing
          _SheetButton(
            icon: Icons.bookmark_add_outlined,
            iconColor: AppColors.gold,
            label: AppLocalizations.of(context).addLead,
            sublabel: AppLocalizations.of(context).addToCrmPipeline,
            enabled: true,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddLeadSheet(fromListing: listing),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
