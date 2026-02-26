import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/repositories/task_repository.dart';
import 'settings_state.dart';

/// Cubit managing the settings screen.
class SettingsCubit extends Cubit<SettingsState> {
  final NotificationService _notificationService;
  final TaskRepository _taskRepository;

  SettingsCubit({
    required NotificationService notificationService,
    required TaskRepository taskRepository,
  })  : _notificationService = notificationService,
        _taskRepository = taskRepository,
        super(const SettingsState());

  /// Load settings info on screen open.
  Future<void> load() async {
    final notifEnabled = await _notificationService.isPermissionGranted();
    final lastSync = _notificationService.lastSyncAt;

    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {
      version = '1.0.0';
    }

    emit(SettingsState(
      notificationsEnabled: notifEnabled,
      lastSyncAt: lastSync,
      appVersion: version,
    ));
  }

  /// Check notification permission status.
  Future<void> checkNotificationPermission() async {
    final enabled = await _notificationService.isPermissionGranted();
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  /// Trigger a manual sync.
  Future<void> syncNow() async {
    emit(state.copyWith(isSyncing: true));

    // Re-fetch today's tasks to sync
    await _taskRepository.getTodayTasks();
    await _notificationService.updateLastSync();

    emit(state.copyWith(
      isSyncing: false,
      lastSyncAt: DateTime.now(),
    ));
  }
}
