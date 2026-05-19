import 'package:equatable/equatable.dart';
import '../../../domain/entities/care_task.dart';

/// Task detail screen states.
abstract class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

class TaskDetailLoaded extends TaskDetailState {
  final CareTask task;
  final List<CareTask> recentCompletions;
  final bool isCompleting;
  final List<String> selectedPhotoPaths;

  const TaskDetailLoaded({
    required this.task,
    this.recentCompletions = const [],
    this.isCompleting = false,
    this.selectedPhotoPaths = const [],
  });

  TaskDetailLoaded copyWith({
    CareTask? task,
    List<CareTask>? recentCompletions,
    bool? isCompleting,
    List<String>? selectedPhotoPaths,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      recentCompletions: recentCompletions ?? this.recentCompletions,
      isCompleting: isCompleting ?? this.isCompleting,
      selectedPhotoPaths: selectedPhotoPaths ?? this.selectedPhotoPaths,
    );
  }

  @override
  List<Object?> get props =>
      [task, recentCompletions, isCompleting, selectedPhotoPaths];
}

class TaskDetailCompleted extends TaskDetailState {
  final CareTask task;
  const TaskDetailCompleted(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskDetailError extends TaskDetailState {
  final String message;
  const TaskDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
