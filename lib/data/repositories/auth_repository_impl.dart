import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_ds.dart';
import '../datasources/remote/auth_remote_ds.dart';

/// Auth repository implementation with network check.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDs;
  final AuthLocalDataSource _localDs;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDs,
    required AuthLocalDataSource localDs,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _remoteDs = remoteDs,
        _localDs = localDs,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDs.login(email, password);
      await _apiClient.saveTokens(result.accessToken, result.refreshToken);
      await _localDs.cacheUser(result.user);
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken() async {
    // Handled by ApiClient interceptor automatically.
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await _networkInfo.isConnected) {
        await _remoteDs.logout();
      }
    } catch (_) {
      // Ignore server errors on logout — clear local state regardless.
    }
    await _apiClient.clearTokens();
    await _localDs.clearUser();
    return const Right(null);
  }

  @override
  Future<User?> getCachedUser() => _localDs.getCachedUser();

  @override
  bool get isAuthenticated => _apiClient.isAuthenticated;
}
