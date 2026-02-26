import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/care_task.dart';
import '../home/widgets/task_card.dart';
import 'cubit/schedule_cubit.dart';
import 'cubit/schedule_state.dart';

/// Schedule screen — week date selector + care type filter + task list.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ScheduleCubit(sl())..loadTasksForDate(DateTime.now()),
      child: const _ScheduleBody(),
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  const _ScheduleBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.schedule)),
      body: Column(
        children: [
          // Week date selector
          const _WeekDateSelector(),
          const SizedBox(height: 8),
          // Filter chips
          const _CareTypeFilter(),
          const SizedBox(height: 8),
          // Task list
          Expanded(
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is ScheduleError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ScheduleCubit>()
                              .loadTasksForDate(DateTime.now()),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ScheduleLoaded) {
                  return _buildTaskList(context, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, ScheduleLoaded state) {
    final tasks = state.filteredTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 48, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              AppStrings.noTasksForDate,
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group tasks by hour
    final grouped = <String, List<CareTask>>{};
    for (final task in tasks) {
      final key = DateFormat.jm().format(task.scheduledAt);
      grouped.putIfAbsent(key, () => []).add(task);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final time = grouped.keys.elementAt(index);
        final group = grouped[time]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                time,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...group.map((task) => TaskCard(
                  task: task,
                  onTap: () => context.push('/task/${task.id}'),
                )),
          ],
        );
      },
    );
  }
}

/// Horizontal scrollable week date selector.
class _WeekDateSelector extends StatelessWidget {
  const _WeekDateSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final selectedDate = state is ScheduleLoaded
            ? state.selectedDate
            : DateTime.now();
        final today = DateTime.now();
        // Show 3 days before + today + 10 days ahead
        final startDate = today.subtract(const Duration(days: 3));

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, today);

              return GestureDetector(
                onTap: () =>
                    context.read<ScheduleCubit>().selectDate(date),
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E().format(date).toUpperCase(),
                        style: AppTypography.overline.copyWith(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: AppTypography.h3.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.MMM().format(date),
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Care type filter chips.
class _CareTypeFilter extends StatelessWidget {
  const _CareTypeFilter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final currentFilter =
            state is ScheduleLoaded ? state.filterType : null;

        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildChip(
                context,
                label: AppStrings.allTypes,
                isSelected: currentFilter == null,
                onTap: () => context.read<ScheduleCubit>().setFilter(null),
              ),
              ...CareType.values.map((type) => _buildChip(
                    context,
                    label: _typeLabel(type),
                    color: AppColors.careTypeColor(type.name),
                    isSelected: currentFilter == type,
                    onTap: () =>
                        context.read<ScheduleCubit>().setFilter(type),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: chipColor.withValues(alpha: 0.2),
        backgroundColor: AppColors.surface,
        labelStyle: AppTypography.caption.copyWith(
          color: isSelected ? chipColor : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  String _typeLabel(CareType type) {
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
        return 'General';
    }
  }
}
