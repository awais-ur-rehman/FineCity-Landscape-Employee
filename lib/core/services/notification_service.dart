import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

const _kNotifications = 'fc_notifications';
const _kLastSync = 'fc_last_sync';

/// Handles FCM push, local notifications, and notification storage.
class NotificationService {
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  final SharedPreferences _prefs;
  final ApiClient? _apiClient;

  /// Whether Firebase/FCM is available.
  bool get isFirebaseAvailable => _messaging != null;

  /// Callback invoked when a notification is tapped with task ID.
  void Function(String taskId)? onNotificationTap;

  /// Full constructor — used when Firebase is initialized.
  NotificationService({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required SharedPreferences prefs,
    required ApiClient apiClient,
  })  : _messaging = messaging,
        _localNotifications = localNotifications,
        _prefs = prefs,
        _apiClient = apiClient;

  /// No-op constructor — used when Firebase is not configured.
  /// Notification storage still works, but FCM is disabled.
  NotificationService.noop({required SharedPreferences prefs})
      : _messaging = null,
        _localNotifications = null,
        _prefs = prefs,
        _apiClient = null;

  /// Initialize local notifications and FCM listeners.
  Future<void> init() async {
    if (_localNotifications == null || _messaging == null) return;

    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'care_tasks',
      'Care Tasks',
      description: 'Notifications for plant care tasks',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // FCM foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // FCM notification tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app launched from terminated by tap)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Check current permission status.
  Future<bool> isPermissionGranted() async {
    if (_messaging == null) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get FCM token and register with backend.
  Future<void> registerFcmToken() async {
    if (_messaging == null || _apiClient == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _apiClient.dio.post(
        ApiEndpoints.fcmToken,
        data: {'fcmToken': token, 'platform': platform},
      );
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) async {
      try {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await _apiClient.dio.post(
          ApiEndpoints.fcmToken,
          data: {'fcmToken': token, 'platform': platform},
        );
      } catch (_) {}
    });
  }

  /// Handle foreground FCM message — show local notification + store.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // Store the notification
    _storeNotification(
      title: notification?.title ?? data['title'] ?? 'Task Update',
      body: notification?.body ?? data['body'] ?? '',
      data: data,
    );

    // Show local notification
    if (notification != null && _localNotifications != null) {
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'care_tasks',
            'Care Tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(data),
      );
    }
  }

  /// Handle notification tap when app is in background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    _markNotificationRead(data['taskId'] as String?);
    final taskId = data['taskId'] as String?;
    if (taskId != null && onNotificationTap != null) {
      onNotificationTap!(taskId);
    }
  }

  /// Handle local notification tap.
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final taskId = data['taskId'] as String?;
      if (taskId != null && onNotificationTap != null) {
        onNotificationTap!(taskId);
      }
    } catch (_) {}
  }

  // ─── Local notification storage ───

  /// Store a notification locally.
  void _storeNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notifications = getStoredNotifications();
    notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'taskId': data?['taskId'],
      'careType': data?['careType'],
      'type': data?['type'],
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });
    // Keep max 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    _prefs.setString(_kNotifications, jsonEncode(notifications));
  }

  /// Get all stored notifications.
  List<Map<String, dynamic>> getStoredNotifications() {
    final jsonStr = _prefs.getString(_kNotifications);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Mark a notification as read by task ID.
  void _markNotificationRead(String? taskId) {
    if (taskId == null) return;
    final notifications = getStoredNotifications();
    for (final n in notifications) {
      if (n['taskId'] == taskId) n['read'] = true;
    }
    _prefs.setString(_kNotifications, jsonEncode(notifications));
  }

  /// Mark a notification as read by notification ID.
  void markRead(String notificationId) {
    final notifications = getStoredNotifications();
    for (final n in notifications) {
      if (n['id'] == notificationId) n['read'] = true;
    }
    _prefs.setString(_kNotifications, jsonEncode(notifications));
  }

  /// Mark all notifications as read.
  void markAllRead() {
    final notifications = getStoredNotifications();
    for (final n in notifications) {
      n['read'] = true;
    }
    _prefs.setString(_kNotifications, jsonEncode(notifications));
  }

  /// Count of unread notifications.
  int get unreadCount {
    return getStoredNotifications().where((n) => n['read'] != true).length;
  }

  // ─── Sync helpers ───

  /// Get last sync timestamp.
  DateTime? get lastSyncAt {
    final str = _prefs.getString(_kLastSync);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Update last sync timestamp.
  Future<void> updateLastSync() async {
    await _prefs.setString(_kLastSync, DateTime.now().toIso8601String());
  }
}

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Store notification data for when app resumes.
  // Full processing happens when app opens.
}
