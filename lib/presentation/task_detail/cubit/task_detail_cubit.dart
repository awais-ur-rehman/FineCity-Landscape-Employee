import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/task_repository.dart';
import 'task_detail_state.dart';

/// Cubit managing the task detail screen.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskRepository _taskRepository;

  TaskDetailCubit(this._taskRepository) : super(const TaskDetailInitial());

  /// Load task details and recent completions.
  Future<void> loadTask(String taskId) async {
    emit(const TaskDetailLoading());

    final taskResult = await _taskRepository.getTaskById(taskId);

    await taskResult.fold(
      (failure) async => emit(TaskDetailError(failure.message)),
      (task) async {
        // Also fetch recent completions for this schedule
        final completionsResult =
            await _taskRepository.getRecentCompletions(task.scheduleId);
        final completions = completionsResult.fold(
          (_) => <dynamic>[],
          (list) => list,
        );
        emit(TaskDetailLoaded(
          task: task,
          recentCompletions: List.from(completions),
        ));
      },
    );
  }

  /// Mark the task as completed with optional notes.
  Future<void> markComplete(String taskId, {String? notes}) async {
    final currentState = state;
    if (currentState is! TaskDetailLoaded) return;

    emit(TaskDetailLoaded(
      task: currentState.task,
      recentCompletions: currentState.recentCompletions,
      isCompleting: true,
    ));

    final result = await _taskRepository.completeTask(taskId, notes: notes);

    result.fold(
      (failure) {
        emit(TaskDetailLoaded(
          task: currentState.task,
          recentCompletions: currentState.recentCompletions,
        ));
        emit(TaskDetailError(failure.message));
        emit(TaskDetailLoaded(
          task: currentState.task,
          recentCompletions: currentState.recentCompletions,
        ));
      },
      (completedTask) {
        emit(TaskDetailCompleted(completedTask));
      },
    );
  }
}
