import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit managing authentication flow.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  /// Check if user is already authenticated on app launch.
  Future<void> checkAuth() async {
    if (_authRepository.isAuthenticated) {
      final user = await _authRepository.getCachedUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
        return;
      }
    }
    emit(const AuthUnauthenticated());
  }

  /// Log in with email and password.
  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await _authRepository.login(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Log out the current user.
  Future<void> logout() async {
    emit(const AuthLoading());
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
