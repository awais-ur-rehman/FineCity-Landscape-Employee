import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/care_task.dart';

/// Abstract task repository contract.
abstract class TaskRepository {
  /// Fetches today's tasks for the current user.
  Future<Either<Failure, List<CareTask>>> getTodayTasks();

  /// Fetches a single task by ID.
  Future<Either<Failure, CareTask>> getTaskById(String id);

  /// Marks a task as completed with optional notes.
  Future<Either<Failure, CareTask>> completeTask(String id, {String? notes});

  /// Fetches tasks for a specific date.
  Future<Either<Failure, List<CareTask>>> getTasksForDate(DateTime date);

  /// Fetches recent completions for a given schedule.
  Future<Either<Failure, List<CareTask>>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  });
}
