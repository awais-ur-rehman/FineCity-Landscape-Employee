import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Verifies OTP and returns the authenticated user.
class VerifyOtp {
  final AuthRepository _repository;

  const VerifyOtp(this._repository);

  Future<Either<Failure, User>> call(String email, String otp) {
    return _repository.verifyOtp(email, otp);
  }
}
