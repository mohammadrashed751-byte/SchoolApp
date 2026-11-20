import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterDriver implements UseCase<Unit, RegisterDriverParams> {
  final AuthRepository repository;
  RegisterDriver(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RegisterDriverParams params) {
    return repository.registerDriver(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      phoneNumber: params.phoneNumber,
      licenseNumber: params.licenseNumber,
      licenseExpiryDate: params.licenseExpiryDate,
    );
  }
}

class RegisterDriverParams extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? licenseNumber;
  final String? licenseExpiryDate;

  const RegisterDriverParams({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.licenseNumber,
    this.licenseExpiryDate,
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        password,
        phoneNumber,
        licenseNumber,
        licenseExpiryDate,
      ];
}
