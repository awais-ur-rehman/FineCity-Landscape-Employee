import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Flat badge for task status — matches admin portal badge style.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    final label = _label(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'due':
        return 'Due';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Done';
      case 'missed':
        return 'Missed';
      case 'skipped':
        return 'Skipped';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }
}
