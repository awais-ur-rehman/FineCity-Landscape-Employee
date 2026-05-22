import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/care_task.dart';
import '../../shared/widgets/care_type_icon.dart';
import '../../shared/widgets/status_badge.dart';

/// Task card — flat design with care type icon anchor. No left border.
class TaskCard extends StatelessWidget {
  final CareTask task;
  final bool isCompleting;
  final VoidCallback? onTap;
  final VoidCallback? onQuickDone;

  const TaskCard({
    super.key,
    required this.task,
    this.isCompleting = false,
    this.onTap,
    this.onQuickDone,
  });

  @override
  Widget build(BuildContext context) {
    final careColor = AppColors.careTypeColor(task.careType.name);
    final timeStr = DateFormat.jm().format(task.scheduledAt);
    final showQuickDone =
        task.status == TaskStatus.pending && (task.isDue || task.isOverdue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Care type icon — visual anchor on left
              CareTypeIcon(careType: task.careType.name, size: 20),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: batch name + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.batchName ?? 'Unknown Batch',
                            style: AppTypography.body2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: _displayStatus),
                      ],
                    ),

                    // Zone + location
                    if (task.zone != null || task.location != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        [task.zone, task.location]
                            .where((s) => s != null)
                            .join(' · '),
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Bottom: care type label + time + done button
                    Row(
                      children: [
                        // Care type label chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: careColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _careTypeLabel,
                            style: AppTypography.overline.copyWith(
                              color: careColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.schedule,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          timeStr,
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        if (showQuickDone) ...[
                          const SizedBox(width: 10),
                          _QuickDoneButton(
                            isLoading: isCompleting,
                            onPressed: onQuickDone,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _displayStatus {
    if (task.status == TaskStatus.pending && task.isOverdue) return 'overdue';
    if (task.status == TaskStatus.pending && task.isDue) return 'due';
    return task.status.name;
  }

  String get _careTypeLabel {
    switch (task.careType) {
      case CareType.watering:
        return 'Watering';
      case CareType.fertilizing:
        return 'Fertilizing';
      case CareType.pruning:
        return 'Pruning';
      case CareType.repotting:
        return 'Repotting';
      case CareType.pestControl:
        return 'Pest Control';
    }
  }
}

class _QuickDoneButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _QuickDoneButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Done',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
