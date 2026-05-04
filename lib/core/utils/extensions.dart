import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── BuildContext extensions ────────────────────────────────────────────────

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── String extensions ──────────────────────────────────────────────────────

extension StringX on String {
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalised).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidMobile => RegExp(r'^[6-9]\d{9}$').hasMatch(this);

  bool get isValidPin => RegExp(r'^\d{6}$').hasMatch(this);

  /// Formats Indian rupee values: "12,50,000" → "₹12.5L"
  String get toRupeeLabel {
    final n = double.tryParse(replaceAll(',', ''));
    if (n == null) return this;
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}K';
    return '₹$this';
  }
}

// ── num extensions ─────────────────────────────────────────────────────────

extension NumX on num {
  String get toRupeeLabel {
    if (this >= 10000000) return '₹${(this / 10000000).toStringAsFixed(2)}Cr';
    if (this >= 100000) return '₹${(this / 100000).toStringAsFixed(2)}L';
    if (this >= 1000) return '₹${(this / 1000).toStringAsFixed(0)}K';
    return '₹${toStringAsFixed(0)}';
  }

  /// Formats large counts: 1200 → "1.2K"
  String get toCompact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toString();
  }
}

// ── DateTime extensions ────────────────────────────────────────────────────

extension DateTimeX on DateTime {
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM y').format(this);
  }

  String get formattedDate => DateFormat('d MMM y').format(this);

  String get formattedDateTime => DateFormat('d MMM y, h:mm a').format(this);
}
