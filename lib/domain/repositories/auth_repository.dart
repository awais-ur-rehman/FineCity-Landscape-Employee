import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract auth repository contract.
abstract class AuthRepository {
  /// Sends OTP to the given email.
  Future<Either<Failure, void>> sendOtp(String email);

  /// Verifies OTP and returns authenticated user.
  Future<Either<Failure, User>> verifyOtp(String email, String otp);

  /// Refreshes access token.
  Future<Either<Failure, void>> refreshToken();

  /// Logs out the current user.
  Future<Either<Failure, void>> logout();

  /// Returns the cached user, if any.
  Future<User?> getCachedUser();

  /// Whether user is currently authenticated.
  bool get isAuthenticated;
}
