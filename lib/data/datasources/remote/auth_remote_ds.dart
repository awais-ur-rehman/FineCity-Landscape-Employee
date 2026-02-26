import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

/// Remote data source for authentication.
abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String email);
  Future<({UserModel user, String accessToken, String refreshToken})> verifyOtp(
      String email, String otp);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<void> sendOtp(String email) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sendOtp,
        data: {'email': email},
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to send OTP',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to send OTP',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<({UserModel user, String accessToken, String refreshToken})> verifyOtp(
      String email, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Invalid OTP',
          statusCode: response.statusCode,
        );
      }
      final data = response.data['data'];
      return (
        user: UserModel.fromJson(data['user']),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Verification failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
