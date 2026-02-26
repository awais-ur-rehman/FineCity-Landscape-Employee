/// API endpoint paths and base URL configuration.
class ApiEndpoints {
  ApiEndpoints._();

  static const baseUrl =
      'http://192.168.18.123:3000/api/v1'; // Android emulator
  static const baseUrlIos = 'http://localhost:3000/api/v1';

  // Auth
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const refreshToken = '/auth/refresh-token';
  static const logout = '/auth/logout';
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
