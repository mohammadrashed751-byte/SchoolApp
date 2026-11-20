import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterSupervisor implements UseCase<Unit, RegisterSupervisorParams> {
  final AuthRepository repository;
  RegisterSupervisor(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RegisterSupervisorParams params) {
    return repository.registerSupervisor(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      phoneNumber: params.phoneNumber,
    );
  }
}

class RegisterSupervisorParams extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;

  const RegisterSupervisorParams({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [fullName, email, password, phoneNumber];
}
