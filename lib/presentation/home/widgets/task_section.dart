import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Section header with title, count badge, and collapsible content.
class TaskSection extends StatelessWidget {
  final String title;
  final int count;
  final Color badgeColor;
  final bool initiallyExpanded;
  final List<Widget> children;

  const TaskSection({
    super.key,
    required this.title,
    required this.count,
    required this.badgeColor,
    this.initiallyExpanded = true,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Text(
              title,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}
