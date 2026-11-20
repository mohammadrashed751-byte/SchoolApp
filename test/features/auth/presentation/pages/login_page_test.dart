import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

import 'auth_test_mocks.dart';

void main() {
  setUpAll(registerAuthUseCaseFallbackValues);

  testWidgets(
      'shows an error SnackBar on AuthActionFailure and stays on LoginPage '
      '(does not navigate away)', (tester) async {
    final cubit = TestAuthCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

    cubit.emitState(AuthActionFailure('Invalid email or password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Invalid email or password'), findsOneWidget);
    // Still on the login form - no navigation happened.
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
  });
}
