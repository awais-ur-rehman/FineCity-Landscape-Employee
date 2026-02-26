import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local/task_local_ds.dart';
import '../datasources/remote/task_remote_ds.dart';

/// Offline-first task repository.
///
/// Reads always come from the local DB.
/// Remote fetches happen in the background and update the local DB.
/// Completions are queued locally when offline and synced later.
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDs;
  final TaskLocalDataSource _localDs;
  final NetworkInfo _networkInfo;
  final NotificationService _notificationService;

  const TaskRepositoryImpl({
    required TaskRemoteDataSource remoteDs,
    required TaskLocalDataSource localDs,
    required NetworkInfo networkInfo,
    required NotificationService notificationService,
  })  : _remoteDs = remoteDs,
        _localDs = localDs,
        _networkInfo = networkInfo,
        _notificationService = notificationService;

  @override
  Future<Either<Failure, List<CareTask>>> getTodayTasks() async {
    // Always try remote first to keep local DB fresh
    if (await _networkInfo.isConnected) {
      try {
        final tasks = await _remoteDs.getTodayTasks();
        await _localDs.upsertTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        debugPrint('Remote fetch failed, falling back to local: ${e.message}');
      }
    }
    // Fallback: read from local DB
    final cached = await _localDs.getCachedTodayTasks();
    if (cached.isNotEmpty) return Right(cached);
    return const Left(NetworkFailure('No cached tasks available'));
  }

  @override
  Future<Either<Failure, CareTask>> getTaskById(String id) async {
    // Try local first (instant)
    final local = await _localDs.getTaskById(id);
    if (local != null) return Right(local);

    // Fallback to remote
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final task = await _remoteDs.getTaskById(id);
      await _localDs.upsertTasks([task]);
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
    // Always update local DB immediately for instant UI feedback
    final localTask = await _localDs.completeTaskLocally(id, notes: notes);

    // Cancel any scheduled local notification for this task
    await _notificationService.cancelTaskReminder(id);

    if (await _networkInfo.isConnected) {
      try {
        final task = await _remoteDs.completeTask(id, notes: notes);
        await _localDs.upsertTasks([task]);
        return Right(task);
      } on ServerException catch (e) {
        // Remote failed but local succeeded — queue for sync
        if (localTask != null) {
          await _localDs.addToSyncQueue(
            taskId: id,
            action: 'complete',
            notes: notes,
            completedAt: DateTime.now(),
          );
          return Right(localTask);
        }
        return Left(ServerFailure(e.message));
      }
    }

    // Offline — queue for sync
    if (localTask != null) {
      await _localDs.addToSyncQueue(
        taskId: id,
        action: 'complete',
        notes: notes,
        completedAt: DateTime.now(),
      );
      return Right(localTask);
    }
    return const Left(NetworkFailure('Task not found locally'));
  }

  @override
  Future<Either<Failure, List<CareTask>>> getTasksForDate(
    DateTime date,
  ) async {
    // Try remote first to refresh local DB
    if (await _networkInfo.isConnected) {
      try {
        final tasks = await _remoteDs.getTasksForDate(date);
        await _localDs.upsertTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        debugPrint('Remote fetch failed, falling back to local: ${e.message}');
      }
    }
    // Fallback to local
    final cached = await _localDs.getTasksForDate(date);
    return Right(cached);
  }

  @override
  Future<Either<Failure, List<CareTask>>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  }) async {
    // Try remote first
    if (await _networkInfo.isConnected) {
      try {
        final tasks = await _remoteDs.getRecentCompletions(
          scheduleId,
          limit: limit,
        );
        await _localDs.upsertTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        debugPrint('Remote fetch failed, falling back to local: ${e.message}');
      }
    }
    // Fallback to local
    final cached = await _localDs.getRecentCompletions(
      scheduleId,
      limit: limit,
    );
    return Right(cached);
  }
}
