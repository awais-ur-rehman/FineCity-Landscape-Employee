import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Icon + color for each care type.
class CareTypeIcon extends StatelessWidget {
  final String careType;
  final double size;

  const CareTypeIcon({super.key, required this.careType, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.careTypeColor(careType);
    final icon = _iconFor(careType);

    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  static IconData _iconFor(String careType) {
    switch (careType) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizer':
        return Icons.eco;
      case 'pruning':
        return Icons.content_cut;
      case 'repotting':
        return Icons.yard;
      case 'general':
      default:
        return Icons.spa;
    }
  }
}
