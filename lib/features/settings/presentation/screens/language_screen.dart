import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      ('en', l.languageEnglish, '🇬🇧'),
      ('hi', l.languageHindi, '🇮🇳'),
      ('gu', l.languageGujarati, '🏛️'),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        title: Text(
          l.chooseLanguage,
          style: AppTypography.titleSmall.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (code, label, flag) = languages[i];
          final isSelected = current.languageCode == code;

          return GestureDetector(
            onTap: () async {
              await ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).languageSaved),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : (isDark ? AppColors.surfaceDark : AppColors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : (isDark ? AppColors.borderDark : AppColors.border),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: isSelected
                            ? AppColors.gold
                            : (isDark
                                ? AppColors.white
                                : AppColors.navyDark),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.gold,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
