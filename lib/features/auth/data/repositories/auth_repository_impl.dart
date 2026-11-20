import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthUser>> login(String email, String password) async {
    try {
      final token = await remoteDataSource.login(email, password);
      localDataSource.setAccessToken(token.accessToken, token.expiresIn);
      await localDataSource.saveRefreshToken(token.refreshToken);

      final user = await remoteDataSource.getMe();
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerParent({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      await remoteDataSource.registerParent(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDriver({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiryDate,
  }) async {
    try {
      await remoteDataSource.registerDriver(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerSupervisor({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      await remoteDataSource.registerSupervisor(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final storedRefreshToken = await localDataSource.readRefreshToken();

    // Local session state is cleared first, unconditionally: a failed
    // network logout must never leave the app looking authenticated.
    localDataSource.clearAccessToken();
    await localDataSource.deleteRefreshToken();

    if (storedRefreshToken != null) {
      try {
        await remoteDataSource.logout(storedRefreshToken);
      } catch (_) {
        // Swallowed by design: logout is guaranteed locally regardless of
        // whether the remote call succeeds.
      }
    }

    return const Right(unit);
  }

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    final storedRefreshToken = await localDataSource.readRefreshToken();
    if (storedRefreshToken == null) {
      return const Left(UnauthorizedFailure('No stored session'));
    }

    try {
      final token = await remoteDataSource.refresh(storedRefreshToken);
      localDataSource.setAccessToken(token.accessToken, token.expiresIn);
      await localDataSource.saveRefreshToken(token.refreshToken);

      final user = await remoteDataSource.getMe();
      return Right(user);
    } on DioException catch (_) {
      localDataSource.clearAccessToken();
      await localDataSource.deleteRefreshToken();
      return const Left(UnauthorizedFailure('Session expired'));
    }
  }

  Failure _mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(e.message ?? 'Network error');
      default:
        break;
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e) ?? 'Unknown server error';

    if (statusCode == 401) {
      return UnauthorizedFailure(message);
    }
    return ServerFailure(message);
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString());
        if (messages.isNotEmpty) return messages.join('; ');
      }

      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return e.message;
  }
}
