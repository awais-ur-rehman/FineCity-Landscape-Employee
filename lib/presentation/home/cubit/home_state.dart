import 'package:equatable/equatable.dart';
import '../../../domain/entities/care_task.dart';

/// Home screen states.
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<CareTask> tasks;
  final String? completingTaskId;

  const HomeLoaded({required this.tasks, this.completingTaskId});

  /// Tasks that are overdue or due now.
  List<CareTask> get dueNowTasks => tasks
      .where((t) =>
          t.status == TaskStatus.pending &&
          (t.isOverdue || t.isDue))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Tasks that are pending but not yet due.
  List<CareTask> get upcomingTasks => tasks
      .where((t) =>
          t.status == TaskStatus.pending &&
          !t.isOverdue &&
          !t.isDue)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Tasks that are completed.
  List<CareTask> get completedTasks => tasks
      .where((t) => t.status == TaskStatus.completed)
      .toList()
    ..sort((a, b) =>
        (b.completedAt ?? b.scheduledAt)
            .compareTo(a.completedAt ?? a.scheduledAt));

  int get totalCount => tasks.length;
  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;

  @override
  List<Object?> get props => [tasks, completingTaskId];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
