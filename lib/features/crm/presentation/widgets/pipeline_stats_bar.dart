import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';

class PipelineStatsBar extends StatelessWidget {
  const PipelineStatsBar({super.key, required this.crmState});

  final CrmState crmState;

  String _formatValue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v > 0) return '₹${v.toStringAsFixed(0)}';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Pipeline',
            value: _formatValue(crmState.pipelineValue),
            valueColor: AppColors.gold,
            isDark: isDark,
          ),
          _Divider(),
          _Stat(
            label: 'Active',
            value: '${crmState.activeCount}',
            valueColor: AppColors.white,
            isDark: isDark,
          ),
          _Divider(),
          _Stat(
            label: 'Closed',
            value: '${crmState.closedCount}',
            valueColor: AppColors.success,
            isDark: isDark,
          ),
          _Divider(),
          _Stat(
            label: 'Total',
            value: '${crmState.leads.length}',
            valueColor: AppColors.white,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.white.withValues(alpha: 0.15),
    );
  }
}
