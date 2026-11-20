import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/pending_approval_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/register_driver_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/register_parent_page.dart';
import 'package:flutter_app/features/auth/presentation/pages/register_supervisor_page.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

import 'auth_test_mocks.dart';

Future<TestAuthCubit> _pumpAtRoute(
  WidgetTester tester, {
  required String initialLocation,
  required Map<String, Widget Function()> routes,
}) async {
  final cubit = TestAuthCubit();
  addTearDown(cubit.close);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes.entries
        .map((entry) => GoRoute(path: entry.key, builder: (context, state) => entry.value()))
        .toList(),
  );

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: cubit,
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  return cubit;
}

void main() {
  setUpAll(registerAuthUseCaseFallbackValues);

  final routes = <String, Widget Function()>{
    '/login': () => const LoginPage(),
    '/register/parent': () => const RegisterParentPage(),
    '/register/driver': () => const RegisterDriverPage(),
    '/register/supervisor': () => const RegisterSupervisorPage(),
    '/pending-approval': () => const PendingApprovalPage(),
  };

  testWidgets('RegisterParentPage navigates to /login (not /pending-approval) on success',
      (tester) async {
    final cubit = await _pumpAtRoute(
      tester,
      initialLocation: '/register/parent',
      routes: routes,
    );

    cubit.emitState(AuthRegistrationSuccess());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
    expect(find.byKey(const Key('backToLoginButton')), findsNothing);
  });

  testWidgets('RegisterDriverPage navigates to /pending-approval on success', (tester) async {
    final cubit = await _pumpAtRoute(
      tester,
      initialLocation: '/register/driver',
      routes: routes,
    );

    cubit.emitState(AuthRegistrationSuccess());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backToLoginButton')), findsOneWidget);
  });

  testWidgets('RegisterSupervisorPage navigates to /pending-approval on success', (tester) async {
    final cubit = await _pumpAtRoute(
      tester,
      initialLocation: '/register/supervisor',
      routes: routes,
    );

    cubit.emitState(AuthRegistrationSuccess());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backToLoginButton')), findsOneWidget);
  });
}
