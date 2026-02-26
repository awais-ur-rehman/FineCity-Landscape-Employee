import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/care_task.dart';
import '../repositories/task_repository.dart';

/// Marks a care task as completed.
class CompleteTask {
  final TaskRepository _repository;

  const CompleteTask(this._repository);

  Future<Either<Failure, CareTask>> call(String taskId, {String? notes}) {
    return _repository.completeTask(taskId, notes: notes);
  }
}
