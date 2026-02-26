import 'package:equatable/equatable.dart';
import '../../../domain/entities/care_task.dart';

/// Schedule screen states.
abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  final List<CareTask> tasks;
  final DateTime selectedDate;
  final CareType? filterType;

  const ScheduleLoaded({
    required this.tasks,
    required this.selectedDate,
    this.filterType,
  });

  /// Tasks filtered by care type, sorted by time.
  List<CareTask> get filteredTasks {
    var result = tasks.toList();
    if (filterType != null) {
      result = result.where((t) => t.careType == filterType).toList();
    }
    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return result;
  }

  @override
  List<Object?> get props => [tasks, selectedDate, filterType];
}

class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
