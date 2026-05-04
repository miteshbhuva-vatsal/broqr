import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// Builds the light and dark [ThemeData] for the app.
/// Call [AppTheme.light] / [AppTheme.dark] in MaterialApp.
abstract final class AppTheme {
  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get light => _build(brightness: Brightness.light);

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.navyDark,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.navyLight,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.navyDark,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.navyDark,
      tertiary: AppColors.navyMid,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: isDark ? AppColors.navyMid : AppColors.white,
      onSurface: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      surfaceContainerHighest:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurfaceVariant:
          isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
      outline: isDark ? AppColors.borderDark : AppColors.border,
      outlineVariant:
          isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.border,
      shadow: AppColors.navyDark,
      scrim: AppColors.scrim,
      inverseSurface: isDark ? AppColors.white : AppColors.navyDark,
      onInverseSurface: isDark ? AppColors.textPrimary : AppColors.white,
      inversePrimary: AppColors.gold,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.navyDark : AppColors.offWhite,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ).apply(
        bodyColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        displayColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.navyDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.08),
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.white : AppColors.navyDark,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.navyMid : AppColors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor:
            isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // ── Navigation Bar (Material 3) ──────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.navyMid : AppColors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gold);
          }
          return IconThemeData(
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          );
        }),
        elevation: 8,
      ),

      // ── Elevated Button ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.white : AppColors.navyDark,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.gold),
        ),
      ),

      // ── Input decoration ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.gold,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.navyLight : AppColors.surfaceLight,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.navyLight : AppColors.navyDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.navyMid : AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.navyMid : AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: isDark ? AppColors.white : AppColors.navyDark,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        ),
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor:
            isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        indicatorColor: AppColors.gold,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelMedium,
        dividerColor: isDark ? AppColors.borderDark : AppColors.border,
      ),
    );
  }
}
