import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/core/usecase/usecase.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_app/features/auth/domain/usecases/login.dart';
import 'package:flutter_app/features/auth/domain/usecases/logout.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_driver.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_parent.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_supervisor.dart';
import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLogin extends Mock implements Login {}

class MockRegisterParent extends Mock implements RegisterParent {}

class MockRegisterDriver extends Mock implements RegisterDriver {}

class MockRegisterSupervisor extends Mock implements RegisterSupervisor {}

class MockLogout extends Mock implements Logout {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockLogin login;
  late MockRegisterParent registerParent;
  late MockRegisterDriver registerDriver;
  late MockRegisterSupervisor registerSupervisor;
  late MockLogout logout;

  const testUser = AuthUser(
    userId: 1,
    email: 'a@a.com',
    roleCode: 'PARENT',
    accountStatus: 'ACTIVE',
  );

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const LoginParams(email: 'a@a.com', password: 'pw'));
    registerFallbackValue(
      const RegisterParentParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
    );
    registerFallbackValue(
      const RegisterDriverParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
    );
    registerFallbackValue(
      const RegisterSupervisorParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    login = MockLogin();
    registerParent = MockRegisterParent();
    registerDriver = MockRegisterDriver();
    registerSupervisor = MockRegisterSupervisor();
    logout = MockLogout();
  });

  AuthCubit buildCubit() => AuthCubit(
        getCurrentUserUseCase: getCurrentUser,
        loginUseCase: login,
        registerParentUseCase: registerParent,
        registerDriverUseCase: registerDriver,
        registerSupervisorUseCase: registerSupervisor,
        logoutUseCase: logout,
      );

  group('bootstrap', () {
    blocTest<AuthCubit, AuthState>(
      'no stored session -> [Loading, Unauthenticated]',
      build: buildCubit,
      setUp: () => when(() => getCurrentUser(any()))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session'))),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );

    blocTest<AuthCubit, AuthState>(
      'stored refresh token but refresh fails -> [Loading, Unauthenticated]',
      build: buildCubit,
      setUp: () => when(() => getCurrentUser(any()))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Session expired'))),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );

    blocTest<AuthCubit, AuthState>(
      'refresh + /me succeed -> [Loading, Authenticated(user)]',
      build: buildCubit,
      setUp: () =>
          when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(testUser)),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (cubit) {
        expect((cubit.state as AuthAuthenticated).user, testUser);
      },
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'success -> [Loading, Authenticated(user)]',
      build: buildCubit,
      setUp: () =>
          when(() => login(any())).thenAnswer((_) async => const Right(testUser)),
      act: (cubit) => cubit.login('a@a.com', 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (cubit) {
        expect((cubit.state as AuthAuthenticated).user, testUser);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'failure -> [Loading, ActionFailure(message)], never Unauthenticated',
      build: buildCubit,
      setUp: () => when(() => login(any()))
          .thenAnswer((_) async => const Left(UnauthorizedFailure('Bad credentials'))),
      act: (cubit) => cubit.login('a@a.com', 'wrong'),
      expect: () => [isA<AuthLoading>(), isA<AuthActionFailure>()],
      verify: (cubit) {
        expect(cubit.state, isA<AuthActionFailure>());
        expect((cubit.state as AuthActionFailure).message, 'Bad credentials');
      },
    );
  });

  group('registerParent', () {
    blocTest<AuthCubit, AuthState>(
      'success -> [Loading, RegistrationSuccess]',
      build: buildCubit,
      setUp: () => when(() => registerParent(any())).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.registerParent(fullName: 'P', email: 'p@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthRegistrationSuccess>()],
    );

    blocTest<AuthCubit, AuthState>(
      '400 failure -> [Loading, ActionFailure]',
      build: buildCubit,
      setUp: () => when(() => registerParent(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Email already in use'))),
      act: (cubit) => cubit.registerParent(fullName: 'P', email: 'p@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthActionFailure>()],
    );
  });

  group('registerDriver', () {
    blocTest<AuthCubit, AuthState>(
      'success -> [Loading, RegistrationSuccess]',
      build: buildCubit,
      setUp: () => when(() => registerDriver(any())).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.registerDriver(fullName: 'D', email: 'd@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthRegistrationSuccess>()],
    );

    blocTest<AuthCubit, AuthState>(
      '400 failure -> [Loading, ActionFailure]',
      build: buildCubit,
      setUp: () => when(() => registerDriver(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Invalid license'))),
      act: (cubit) => cubit.registerDriver(fullName: 'D', email: 'd@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthActionFailure>()],
    );
  });

  group('registerSupervisor', () {
    blocTest<AuthCubit, AuthState>(
      'success -> [Loading, RegistrationSuccess]',
      build: buildCubit,
      setUp: () =>
          when(() => registerSupervisor(any())).thenAnswer((_) async => const Right(unit)),
      act: (cubit) =>
          cubit.registerSupervisor(fullName: 'S', email: 's@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthRegistrationSuccess>()],
    );

    blocTest<AuthCubit, AuthState>(
      '400 failure -> [Loading, ActionFailure]',
      build: buildCubit,
      setUp: () => when(() => registerSupervisor(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Email already in use'))),
      act: (cubit) =>
          cubit.registerSupervisor(fullName: 'S', email: 's@a.com', password: 'pw'),
      expect: () => [isA<AuthLoading>(), isA<AuthActionFailure>()],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'always ends in Unauthenticated when the usecase succeeds',
      build: buildCubit,
      setUp: () => when(() => logout(any())).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.logout(),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthCubit, AuthState>(
      'always ends in Unauthenticated even if the usecase reports a failure',
      build: buildCubit,
      setUp: () => when(() => logout(any()))
          .thenAnswer((_) async => const Left(NetworkFailure('offline'))),
      act: (cubit) => cubit.logout(),
      expect: () => [isA<AuthUnauthenticated>()],
    );
  });
}
