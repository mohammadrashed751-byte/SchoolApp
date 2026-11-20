import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_app/features/auth/data/models/auth_token_model.dart';
import 'package:flutter_app/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

DioException _badResponse(String path, int statusCode, {Object? data}) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthRepositoryImpl repository;

  const testToken = AuthTokenModel(
    accessToken: 'accessToken123',
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshToken: 'refreshToken123',
  );
  const testUser = AuthUserModel(
    userId: 1,
    email: 'parent@example.com',
    roleCode: 'PARENT',
    accountStatus: 'ACTIVE',
  );

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);

    when(() => local.setAccessToken(any(), any())).thenReturn(null);
    when(() => local.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => local.deleteRefreshToken()).thenAnswer((_) async {});
    when(() => local.clearAccessToken()).thenReturn(null);
  });

  group('login', () {
    test('success: persists tokens and returns the full user from /me', () async {
      when(() => remote.login('a@a.com', 'pw')).thenAnswer((_) async => testToken);
      when(() => remote.getMe()).thenAnswer((_) async => testUser);

      final result = await repository.login('a@a.com', 'pw');

      expect(result, const Right<Failure, dynamic>(testUser));
      verify(() => local.setAccessToken('accessToken123', 3600)).called(1);
      verify(() => local.saveRefreshToken('refreshToken123')).called(1);
    });

    test('401 maps to UnauthorizedFailure', () async {
      when(() => remote.login('a@a.com', 'wrong'))
          .thenThrow(_badResponse('/api/v1/auth/login', 401));

      final result = await repository.login('a@a.com', 'wrong');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a Left'),
      );
    });
  });

  group('registerParent / registerDriver / registerSupervisor', () {
    test('registerParent success returns Right(unit)', () async {
      when(() => remote.registerParent(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            phoneNumber: any(named: 'phoneNumber'),
          )).thenAnswer((_) async {});

      final result = await repository.registerParent(
        fullName: 'P',
        email: 'p@a.com',
        password: 'pw',
      );

      expect(result, const Right<Failure, dynamic>(unit));
    });

    test('registerDriver 400 maps to ServerFailure using ProblemDetails detail', () async {
      when(() => remote.registerDriver(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            phoneNumber: any(named: 'phoneNumber'),
            licenseNumber: any(named: 'licenseNumber'),
            licenseExpiryDate: any(named: 'licenseExpiryDate'),
          )).thenThrow(_badResponse(
        '/api/v1/auth/register/driver',
        400,
        data: {'detail': 'Email already in use'},
      ));

      final result = await repository.registerDriver(
        fullName: 'D',
        email: 'd@a.com',
        password: 'pw',
      );

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Email already in use');
        },
        (_) => fail('expected a Left'),
      );
    });

    test('registerSupervisor 400 maps to ServerFailure', () async {
      when(() => remote.registerSupervisor(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            phoneNumber: any(named: 'phoneNumber'),
          )).thenThrow(_badResponse('/api/v1/auth/register/supervisor', 400));

      final result = await repository.registerSupervisor(
        fullName: 'S',
        email: 's@a.com',
        password: 'pw',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('logout', () {
    test('clears local state even when the remote call throws', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => 'storedRefreshToken');
      when(() => remote.logout('storedRefreshToken')).thenThrow(
        _badResponse('/api/v1/auth/logout', 500),
      );

      final result = await repository.logout();

      expect(result, const Right<Failure, dynamic>(unit));
      verify(() => local.clearAccessToken()).called(1);
      verify(() => local.deleteRefreshToken()).called(1);
      verify(() => remote.logout('storedRefreshToken')).called(1);
    });

    test('still clears local state and returns Right(unit) when remote succeeds', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => 'storedRefreshToken');
      when(() => remote.logout('storedRefreshToken')).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right<Failure, dynamic>(unit));
      verify(() => local.clearAccessToken()).called(1);
      verify(() => local.deleteRefreshToken()).called(1);
    });
  });

  group('getCurrentUser (session bootstrap)', () {
    test('no stored refresh token -> Left(UnauthorizedFailure), no network call', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a Left'),
      );
      verifyNever(() => remote.refresh(any()));
    });

    test('refresh fails -> clears local state, Left(UnauthorizedFailure)', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => 'oldRefreshToken');
      when(() => remote.refresh('oldRefreshToken'))
          .thenThrow(_badResponse('/api/v1/auth/refresh', 401));

      final result = await repository.getCurrentUser();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a Left'),
      );
      verify(() => local.clearAccessToken()).called(1);
      verify(() => local.deleteRefreshToken()).called(1);
    });

    test('refresh + me succeed -> Right(AuthUser), rotated token persisted', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => 'oldRefreshToken');
      when(() => remote.refresh('oldRefreshToken')).thenAnswer((_) async => testToken);
      when(() => remote.getMe()).thenAnswer((_) async => testUser);

      final result = await repository.getCurrentUser();

      expect(result, const Right<Failure, dynamic>(testUser));
      verify(() => local.setAccessToken('accessToken123', 3600)).called(1);
      verify(() => local.saveRefreshToken('refreshToken123')).called(1);
    });
  });
}
