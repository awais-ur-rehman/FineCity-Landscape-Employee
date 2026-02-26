import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/task_local_ds.dart';
import '../../data/models/care_task_model.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import 'notification_service.dart';

const _kLastSyncAt = 'fc_last_sync';

/// Manages background sync between local DB and server.
class SyncService {
  final ApiClient _apiClient;
  final TaskLocalDataSource _localDs;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final Connectivity _connectivity;

  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  /// Callback when sync completes (so cubits can refresh).
  VoidCallback? onSyncComplete;

  SyncService({
    required ApiClient apiClient,
    required TaskLocalDataSource localDs,
    required NetworkInfo networkInfo,
    required SharedPreferences prefs,
    required Connectivity connectivity,
    required NotificationService notificationService,
  })  : _apiClient = apiClient,
        _localDs = localDs,
        _networkInfo = networkInfo,
        _prefs = prefs,
        _connectivity = connectivity,
        _notificationService = notificationService;

  /// Start periodic sync (every 5 minutes) and connectivity listener.
  void start() {
    // Periodic sync every 5 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncNow(),
    );

    // Sync when connectivity is restored
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
  }

  /// Stop periodic sync and connectivity listener.
  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Get last sync timestamp.
  DateTime? get lastSyncAt {
    final str = _prefs.getString(_kLastSyncAt);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Run a full sync cycle.
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    if (!await _networkInfo.isConnected) return false;
    if (!_apiClient.isAuthenticated) return false;

    _isSyncing = true;
    try {
      // 1. Get pending offline completions from sync queue
      final queue = await _localDs.getSyncQueue();
      final completedTasks = queue.map((item) => {
        'taskId': item['task_id'],
        'completedAt': item['completed_at'],
        'notes': item['notes'],
      }).toList();

      // 2. POST /sync with lastSyncAt + queued completions
      final response = await _apiClient.dio.post(
        ApiEndpoints.sync,
        data: {
          'lastSyncAt': lastSyncAt?.toIso8601String() ??
              DateTime(2000).toIso8601String(),
          'completedTasks': completedTasks,
        },
      );

      if (response.data['success'] != true) {
        debugPrint('Sync failed: ${response.data['message']}');
        return false;
      }

      final data = response.data['data'] as Map<String, dynamic>;

      // 3. Upsert received tasks into local DB
      final tasksJson = data['tasks'] as List<dynamic>? ?? [];
      if (tasksJson.isNotEmpty) {
        final tasks = tasksJson
            .map((t) => CareTaskModel.fromJson(t as Map<String, dynamic>))
            .toList();
        await _localDs.upsertTasks(tasks);

        // Schedule local notifications for pending tasks due within 24 hours
        await _scheduleTaskNotifications(tasks);
      }

      // 4. Clear processed sync queue items
      if (queue.isNotEmpty) {
        final ids = queue.map((item) => item['id'] as int).toList();
        await _localDs.clearSyncQueue(ids);
      }

      // 5. Update last sync timestamp
      final syncedAt = data['syncedAt'] as String? ??
          DateTime.now().toIso8601String();
      await _prefs.setString(_kLastSyncAt, syncedAt);

      // 6. Notify listeners
      onSyncComplete?.call();

      debugPrint('Sync complete: ${tasksJson.length} tasks updated');
      return true;
    } on DioException catch (e) {
      debugPrint('Sync error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Schedule local reminder notifications for pending tasks due within 24 hours.
  /// Each reminder fires 10 minutes before the task's scheduledAt time.
  /// Completed/missed tasks have their reminders cancelled.
  Future<void> _scheduleTaskNotifications(List<CareTaskModel> tasks) async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    final reminderOffset = const Duration(minutes: 10);

    for (final task in tasks) {
      // Cancel reminders for non-pending tasks
      if (task.status.name != 'pending') {
        await _notificationService.cancelTaskReminder(task.id);
        continue;
      }

      if (task.scheduledAt.isBefore(now) || task.scheduledAt.isAfter(cutoff)) {
        continue;
      }

      final reminderTime = task.scheduledAt.subtract(reminderOffset);
      // Only schedule if reminder time is still in the future
      if (reminderTime.isBefore(now)) continue;

      final careLabel = task.careType.name[0].toUpperCase() +
          task.careType.name.substring(1);
      final title = 'Reminder: $careLabel in 10 min — ${task.batchName ?? 'Plant Care'}';
      final body = task.instructions ?? 'Upcoming care task';

      await _notificationService.scheduleTaskReminder(
        taskId: task.id,
        title: title,
        body: body,
        scheduledTime: reminderTime,
      );
    }
  }
}
