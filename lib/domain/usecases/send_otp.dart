import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Logs in with email and password.
class Login {
  final AuthRepository _repository;

  const Login(this._repository);

  Future<Either<Failure, User>> call(String email, String password) {
    return _repository.login(email, password);
  }
}
