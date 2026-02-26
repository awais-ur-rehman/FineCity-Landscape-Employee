import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/care_task.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/care_type_icon.dart';
import '../shared/widgets/status_badge.dart';
import 'cubit/task_detail_cubit.dart';
import 'cubit/task_detail_state.dart';

/// Task detail screen — full task info with mark-done action.
class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailCubit(sl())..loadTask(taskId),
      child: _TaskDetailBody(taskId: taskId),
    );
  }
}

class _TaskDetailBody extends StatefulWidget {
  final String taskId;
  const _TaskDetailBody({required this.taskId});

  @override
  State<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends State<_TaskDetailBody> {
  final _notesController = TextEditingController();
  bool _showNotes = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<TaskDetailCubit, TaskDetailState>(
        listener: (context, state) {
          if (state is TaskDetailCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.taskCompleted),
                backgroundColor: AppColors.statusCompleted,
              ),
            );
            context.pop(true); // Return true to signal completion
          }
          if (state is TaskDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusOverdue,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is TaskDetailLoaded) {
            return _buildContent(context, state);
          }
          if (state is TaskDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<TaskDetailCubit>()
                        .loadTask(widget.taskId),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TaskDetailLoaded state) {
    final task = state.task;
    final careColor = AppColors.careTypeColor(task.careType.name);
    final timeStr = DateFormat.jm().format(task.scheduledAt);
    final dateStr = DateFormat.yMMMd().format(task.scheduledAt);
    final canComplete = task.status == TaskStatus.pending;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Batch info card
                _buildBatchCard(task),
                const SizedBox(height: 16),

                // Care type + time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CareTypeIcon(careType: task.careType.name, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _careTypeLabel(task.careType),
                              style: AppTypography.h3.copyWith(
                                color: careColor,
                              ),
                            ),
                            Text(
                              '$dateStr at $timeStr',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: _displayStatus(task)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions
                if (task.instructions != null &&
                    task.instructions!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions',
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.instructions!,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes input (expandable)
                if (canComplete) ...[
                  GestureDetector(
                    onTap: () => setState(() => _showNotes = !_showNotes),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showNotes
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.addNotes,
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (_showNotes) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Any observations or notes...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Recent completions
                if (state.recentCompletions.isNotEmpty)
                  _buildRecentCompletions(state.recentCompletions),
              ],
            ),
          ),
        ),

        // Bottom action button
        if (canComplete)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: AppPrimaryButton(
              label: AppStrings.markDone,
              isLoading: state.isCompleting,
              onPressed: () {
                final notes = _notesController.text.trim();
                context.read<TaskDetailCubit>().markComplete(
                      widget.taskId,
                      notes: notes.isNotEmpty ? notes : null,
                    );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBatchCard(CareTask task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Plant type icon placeholder (or image)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_florist,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.batchName ?? 'Unknown Batch',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.scientificName != null)
                  Text(
                    task.scientificName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (task.zone != null || task.location != null)
                  Text(
                    [
                      if (task.zone != null) 'Zone ${task.zone}',
                      if (task.location != null) task.location,
                    ].join(' • '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCompletions(List<CareTask> completions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Completions',
            style: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...completions.map((c) {
            final when = c.completedAt != null
                ? DateFormat.yMMMd().add_jm().format(c.completedAt!)
                : 'Unknown';
            final who = c.completedBy ?? 'Unknown';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.statusCompleted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      who,
                      style: AppTypography.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    when,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _displayStatus(CareTask task) {
    if (task.status == TaskStatus.pending && task.isOverdue) return 'overdue';
    if (task.status == TaskStatus.pending && task.isDue) return 'due';
    return task.status.name;
  }

  String _careTypeLabel(CareType type) {
    switch (type) {
      case CareType.watering:
        return 'Watering';
      case CareType.fertilizer:
        return 'Fertilizer';
      case CareType.pruning:
        return 'Pruning';
      case CareType.repotting:
        return 'Repotting';
      case CareType.general:
        return 'General Care';
    }
  }
}
