import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API endpoint paths and base URL configuration.
/// Base URL is loaded from the .env file (API_BASE_URL key).
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';

  // Auth
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh-token';
  static const logout = '/auth/logout';
  static const changePassword = '/auth/change-password';
  static const fcmToken = '/auth/fcm-token';

  // Plant batches
  static const plantBatches = '/plant-batches';

  // Care schedules
  static const careSchedules = '/care-schedules';

  // Care tasks
  static const careTasks = '/care-tasks';
  static String completeTask(String id) => '/care-tasks/$id/complete';
  static String skipTask(String id) => '/care-tasks/$id/skip';
  static const taskStats = '/care-tasks/stats';

  // Sync
  static const sync = '/sync';

  // Users
  static const users = '/users';
}
