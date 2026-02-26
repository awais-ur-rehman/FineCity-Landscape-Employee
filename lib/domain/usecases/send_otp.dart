import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Sends an OTP to the given email address.
class SendOtp {
  final AuthRepository _repository;

  const SendOtp(this._repository);

  Future<Either<Failure, void>> call(String email) {
    return _repository.sendOtp(email);
  }
}
