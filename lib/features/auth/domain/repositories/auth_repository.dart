import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password);

  Future<Either<Failure, Unit>> registerParent({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<Either<Failure, Unit>> registerDriver({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiryDate,
  });

  Future<Either<Failure, Unit>> registerSupervisor({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<Either<Failure, Unit>> logout();

  /// Session bootstrap: reads the stored refresh token, exchanges it for a
  /// fresh access token via /auth/refresh, then loads /auth/me. Returns
  /// `Left(UnauthorizedFailure)` without any network call if no refresh
  /// token is stored, and also on refresh failure (after clearing local
  /// session state).
  Future<Either<Failure, AuthUser>> getCurrentUser();
}
