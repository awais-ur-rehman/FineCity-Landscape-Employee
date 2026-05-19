import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/care_task.dart';
import '../../shared/widgets/care_type_icon.dart';
import '../../shared/widgets/status_badge.dart';

/// Task card with colored left border, batch info, and quick actions.
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: careColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: batch name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.batchName ?? 'Unknown Batch',
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: _displayStatus),
                ],
              ),
              const SizedBox(height: 4),
              // Zone + location
              if (task.zone != null || task.location != null)
                Text(
                  [task.zone, task.location]
                      .where((s) => s != null)
                      .join(' • '),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              // Bottom row: care type + time + quick done
              Row(
                children: [
                  CareTypeIcon(careType: task.careType.name, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _careTypeLabel,
                    style: AppTypography.body2.copyWith(color: careColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (showQuickDone) ...[
                    const SizedBox(width: 12),
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
      height: 32,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Done', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}
