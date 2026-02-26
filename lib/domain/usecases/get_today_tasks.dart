import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/care_task.dart';
import '../repositories/task_repository.dart';

/// Fetches today's tasks for the current user.
class GetTodayTasks {
  final TaskRepository _repository;

  const GetTodayTasks(this._repository);

  Future<Either<Failure, List<CareTask>>> call() {
    return _repository.getTodayTasks();
  }
}
