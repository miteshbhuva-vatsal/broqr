import 'package:flutter/material.dart';

/// Centralised colour palette — deep navy + gold + clean white.
/// All colours are defined as static constants for compile-time safety.
abstract final class AppColors {
  // ── Brand primaries ──────────────────────────────────────────────────────
  static const Color navyDark = Color(0xFF0A1628);
  static const Color navyMid = Color(0xFF132040);
  static const Color navyLight = Color(0xFF1E3060);

  // ── Gold accent ───────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFE8C46A);
  static const Color goldDark = Color(0xFFAD8528);

  // ── Neutral / surface ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFF0F2F5);
  static const Color surfaceDark = Color(0xFF1A2A45);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textHint = Color(0xFFADB5CC);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFB8C4DB);

  // ── Status / semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Category badge colours ────────────────────────────────────────────────
  static const Color catBarterDeal      = Color(0xFFEA580C); // orange
  static const Color catBankAuction     = Color(0xFF4F46E5); // indigo
  static const Color catBigDiscount     = Color(0xFF9333EA); // purple
  static const Color catPreLeased       = Color(0xFF0891B2); // cyan
  static const Color catPreLaunched     = Color(0xFF2563EB); // blue
  static const Color catPreOwned        = Color(0xFFD97706); // amber
  static const Color catBestRoi         = Color(0xFF16A34A); // green
  static const Color catProjectSpecific = Color(0xFF0F766E); // teal

  // ── Divider / border ──────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D3F5E);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color scrim = Color(0x80000000);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // ── Gradient helpers ──────────────────────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyLight],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDark, goldLight],
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0A1628)],
  );
}
