import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

import '../../features/auth/presentation/pages/auth_test_mocks.dart';
import '../../features/parent/presentation/pages/parent_test_mocks.dart';

AuthUser _userWithRole(String roleCode) => AuthUser(
      userId: 1,
      email: 'a@a.com',
      roleCode: roleCode,
      accountStatus: 'ACTIVE',
    );

/// [buildAppRouter] now requires factories for the /parent route's Cubits.
/// Tests that never navigate to /parent pass factories that fail loudly if
/// ever invoked, so an accidental dependency on them is caught immediately.
GoRouter _routerWithoutParentFeature(AuthCubit cubit) {
  return buildAppRouter(
    cubit,
    createParentGateCubit: () =>
        throw StateError('ParentGateCubit should not be created in this test'),
    createLinkRequestCubit: () =>
        throw StateError('LinkRequestCubit should not be created in this test'),
  );
}

void main() {
  setUpAll(() {
    registerAuthUseCaseFallbackValues();
    registerParentUseCaseFallbackValues();
  });

  testWidgets(
      'AuthUnauthenticated bootstrap result at /splash ends at /login, '
      'then AuthAuthenticated (Driver) ends at /driver/home', (tester) async {
    final getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session')));

    final cubit = TestAuthCubit(getCurrentUser: getCurrentUser);
    addTearDown(cubit.close);
    final router = _routerWithoutParentFeature(cubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    cubit.emitState(AuthAuthenticated(_userWithRole('Driver')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(find.text('Driver'), findsWidgets);
  });

  testWidgets('AuthAuthenticated (Supervisor) at /login ends at /supervisor/home',
      (tester) async {
    final getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session')));

    final cubit = TestAuthCubit(getCurrentUser: getCurrentUser);
    addTearDown(cubit.close);
    final router = _routerWithoutParentFeature(cubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    cubit.emitState(AuthAuthenticated(_userWithRole('Supervisor')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(find.text('Supervisor'), findsWidgets);
  });

  testWidgets('AuthAuthenticated (Parent) at /login ends at /parent', (tester) async {
    final getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session')));

    final getMyStudents = MockGetMyStudents();
    when(() => getMyStudents(any())).thenAnswer((_) async => const Right([]));
    final getMyLinkRequests = MockGetMyLinkRequests();
    when(() => getMyLinkRequests(any())).thenAnswer((_) async => const Right([]));
    final submitLinkRequest = MockSubmitLinkRequest();

    final cubit = TestAuthCubit(getCurrentUser: getCurrentUser);
    addTearDown(cubit.close);
    final router = buildAppRouter(
      cubit,
      createParentGateCubit: () => buildTestParentGateCubit(getMyStudents),
      createLinkRequestCubit: () => buildTestLinkRequestCubit(
        submitLinkRequest: submitLinkRequest,
        getMyLinkRequests: getMyLinkRequests,
      ),
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    cubit.emitState(AuthAuthenticated(_userWithRole('Parent')));
    await tester.pumpAndSettle();

    // No approved students yet -> ParentGatePage renders the student-code
    // entry content in place.
    expect(find.byKey(const Key('submitStudentCodeButton')), findsOneWidget);
  });

  testWidgets('an unrecognized roleCode falls back to /login instead of crashing',
      (tester) async {
    final getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session')));

    final cubit = TestAuthCubit(getCurrentUser: getCurrentUser);
    addTearDown(cubit.close);
    final router = _routerWithoutParentFeature(cubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    cubit.emitState(AuthAuthenticated(_userWithRole('Admin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
  });

  testWidgets('/pending-approval is not redirected away from while Unauthenticated',
      (tester) async {
    final getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('No stored session')));

    final cubit = TestAuthCubit(getCurrentUser: getCurrentUser);
    addTearDown(cubit.close);
    final router = _routerWithoutParentFeature(cubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    router.go('/pending-approval');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backToLoginButton')), findsOneWidget);

    // Still Unauthenticated; a redirect re-evaluation must not move us away.
    cubit.emitState(AuthUnauthenticated());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backToLoginButton')), findsOneWidget);
  });
}
