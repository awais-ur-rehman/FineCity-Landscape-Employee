import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local/task_local_ds.dart';
import '../datasources/remote/task_remote_ds.dart';

/// Task repository: tries remote first, falls back to local cache.
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDs;
  final TaskLocalDataSource _localDs;
  final NetworkInfo _networkInfo;

  const TaskRepositoryImpl({
    required TaskRemoteDataSource remoteDs,
    required TaskLocalDataSource localDs,
    required NetworkInfo networkInfo,
  })  : _remoteDs = remoteDs,
        _localDs = localDs,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<CareTask>>> getTodayTasks() async {
    if (await _networkInfo.isConnected) {
      try {
        final tasks = await _remoteDs.getTodayTasks();
        await _localDs.cacheTodayTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    }
    // Offline fallback
    final cached = await _localDs.getCachedTodayTasks();
    if (cached.isNotEmpty) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, CareTask>> getTaskById(String id) async {
    if (!await _networkInfo.isConnected) {
      // Try to find in local cache
      final cached = await _localDs.getCachedTodayTasks();
      final match = cached.where((t) => t.id == id);
      if (match.isNotEmpty) return Right(match.first);
      return const Left(NetworkFailure());
    }
    try {
      final task = await _remoteDs.getTaskById(id);
      return Right(task);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CareTask>> completeTask(
    String id, {
    String? notes,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet — task saved offline'));
    }
    try {
      final task = await _remoteDs.completeTask(id, notes: notes);
      return Right(task);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CareTask>>> getTasksForDate(DateTime date) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final tasks = await _remoteDs.getTasksForDate(date);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CareTask>>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final tasks =
          await _remoteDs.getRecentCompletions(scheduleId, limit: limit);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
