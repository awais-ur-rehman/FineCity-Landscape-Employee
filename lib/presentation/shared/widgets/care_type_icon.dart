import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Square icon container per care type.
class CareTypeIcon extends StatelessWidget {
  final String careType;
  final double size;

  const CareTypeIcon({super.key, required this.careType, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.careTypeColor(careType);
    final icon = _iconFor(careType);

    return Container(
      width: size + 14,
      height: size + 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  static IconData _iconFor(String careType) {
    switch (careType) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizer':
      case 'fertilizing':
        return Icons.eco;
      case 'pruning':
        return Icons.content_cut;
      case 'repotting':
        return Icons.yard;
      case 'pestControl':
      case 'pest_control':
      case 'pestcontrol':
        return Icons.bug_report;
      case 'general':
      default:
        return Icons.spa;
    }
  }
}
