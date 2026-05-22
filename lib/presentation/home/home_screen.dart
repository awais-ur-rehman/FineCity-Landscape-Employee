import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'widgets/daily_progress.dart';
import 'widgets/task_card.dart';
import 'widgets/task_section.dart';

/// Home screen — today's tasks with greeting header.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadTodayTasks();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  String get _userName {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.name.split(' ').first;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMd().format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state is HomeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.statusOverdue,
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<HomeCubit>().refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(today, state),
                  ),
                  // Content
                  if (state is HomeLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (state is HomeLoaded)
                    ..._buildTaskSections(state)
                  else if (state is HomeError)
                    SliverFillRemaining(
                      child: _buildErrorState(state),
                    )
                  else
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String today, HomeState state) {
    final completed =
        state is HomeLoaded ? state.completedCount : 0;
    final total = state is HomeLoaded ? state.totalCount : 0;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 380 ? 16.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _userName,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  today,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DailyProgress(
            completed: completed,
            total: total,
            size: screenWidth < 380 ? 68 : 76,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskSections(HomeLoaded state) {
    final dueNow = state.dueNowTasks;
    final upcoming = state.upcomingTasks;
    final completed = state.completedTasks;

    // Empty state
    if (state.totalCount == 0) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: AppTypography.h3.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.noTasks,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      // Due Now section
      SliverToBoxAdapter(
        child: TaskSection(
          title: AppStrings.dueNow,
          count: dueNow.length,
          badgeColor: AppColors.statusOverdue,
          children: dueNow
              .map((task) => TaskCard(
                    task: task,
                    isCompleting: state.completingTaskId == task.id,
                    onTap: () => context.push('/task/${task.id}'),
                    onQuickDone: () =>
                        context.read<HomeCubit>().completeTask(task.id),
                  ))
              .toList(),
        ),
      ),
      // Upcoming section
      SliverToBoxAdapter(
        child: TaskSection(
          title: AppStrings.upcoming,
          count: upcoming.length,
          badgeColor: AppColors.statusPending,
          children: upcoming
              .map((task) => TaskCard(
                    task: task,
                    onTap: () => context.push('/task/${task.id}'),
                  ))
              .toList(),
        ),
      ),
      // Completed section (collapsed by default)
      SliverToBoxAdapter(
        child: TaskSection(
          title: AppStrings.completed,
          count: completed.length,
          badgeColor: AppColors.statusCompleted,
          initiallyExpanded: false,
          children: completed
              .map((task) => TaskCard(
                    task: task,
                    onTap: () => context.push('/task/${task.id}'),
                  ))
              .toList(),
        ),
      ),
      // Bottom padding
      const SliverToBoxAdapter(
        child: SizedBox(height: 24),
      ),
    ];
  }

  Widget _buildErrorState(HomeError state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.statusOverdue),
          const SizedBox(height: 16),
          Text(state.message, style: AppTypography.body1),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().loadTodayTasks(),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
