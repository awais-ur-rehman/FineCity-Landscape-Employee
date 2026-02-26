import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/care_task.dart';
import '../../../domain/repositories/task_repository.dart';
import 'schedule_state.dart';

/// Cubit managing the schedule screen.
class ScheduleCubit extends Cubit<ScheduleState> {
  final TaskRepository _taskRepository;

  ScheduleCubit(this._taskRepository) : super(const ScheduleInitial());

  /// Load tasks for a specific date.
  Future<void> loadTasksForDate(DateTime date) async {
    final currentFilter =
        state is ScheduleLoaded ? (state as ScheduleLoaded).filterType : null;
    emit(const ScheduleLoading());
    final result = await _taskRepository.getTasksForDate(date);
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (tasks) => emit(ScheduleLoaded(
        tasks: tasks,
        selectedDate: date,
        filterType: currentFilter,
      )),
    );
  }

  /// Change the selected date.
  Future<void> selectDate(DateTime date) async {
    await loadTasksForDate(date);
  }

  /// Filter by care type.
  void setFilter(CareType? type) {
    final currentState = state;
    if (currentState is! ScheduleLoaded) return;
    emit(ScheduleLoaded(
      tasks: currentState.tasks,
      selectedDate: currentState.selectedDate,
      filterType: type,
    ));
  }
}
