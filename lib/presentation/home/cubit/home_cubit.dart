import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/task_repository.dart';
import 'home_state.dart';

/// Cubit managing the home screen task list.
class HomeCubit extends Cubit<HomeState> {
  final TaskRepository _taskRepository;

  HomeCubit(this._taskRepository) : super(const HomeInitial());

  /// Load today's tasks.
  Future<void> loadTodayTasks() async {
    emit(const HomeLoading());
    final result = await _taskRepository.getTodayTasks();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (tasks) => emit(HomeLoaded(tasks: tasks)),
    );
  }

  /// Refresh tasks (pull-to-refresh).
  Future<void> refresh() async {
    final result = await _taskRepository.getTodayTasks();
    result.fold(
      (failure) {
        // On refresh failure, keep existing data if available
        if (state is HomeLoaded) return;
        emit(HomeError(failure.message));
      },
      (tasks) => emit(HomeLoaded(tasks: tasks)),
    );
  }

  /// Complete a task with optional notes.
  Future<void> completeTask(String taskId, {String? notes}) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Show loading indicator on the specific task
    emit(HomeLoaded(
      tasks: currentState.tasks,
      completingTaskId: taskId,
    ));

    final result = await _taskRepository.completeTask(taskId, notes: notes);
    result.fold(
      (failure) {
        // Revert — clear completing indicator
        emit(HomeLoaded(tasks: currentState.tasks));
        // Emit error briefly then revert to loaded
        emit(HomeError(failure.message));
        emit(HomeLoaded(tasks: currentState.tasks));
      },
      (completedTask) {
        // Replace the task in the list with the completed version
        final updatedTasks = currentState.tasks.map((t) {
          return t.id == taskId ? completedTask : t;
        }).toList();
        emit(HomeLoaded(tasks: updatedTasks));
      },
    );
  }
}
