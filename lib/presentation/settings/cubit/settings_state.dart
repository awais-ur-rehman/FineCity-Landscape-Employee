import 'package:equatable/equatable.dart';

/// Settings screen states.
class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final String? appVersion;

  const SettingsState({
    this.notificationsEnabled = false,
    this.lastSyncAt,
    this.isSyncing = false,
    this.appVersion,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    DateTime? lastSyncAt,
    bool? isSyncing,
    String? appVersion,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props =>
      [notificationsEnabled, lastSyncAt, isSyncing, appVersion];
}
