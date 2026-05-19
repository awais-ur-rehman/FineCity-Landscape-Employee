import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract auth repository contract.
abstract class AuthRepository {
  /// Logs in with email and password.
  Future<Either<Failure, User>> login(String email, String password);

  /// Refreshes access token.
  Future<Either<Failure, void>> refreshToken();

  /// Logs out the current user.
  Future<Either<Failure, void>> logout();

  /// Returns the cached user, if any.
  Future<User?> getCachedUser();

  /// Whether user is currently authenticated.
  bool get isAuthenticated;
}
