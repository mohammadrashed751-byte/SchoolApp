import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/pages/register_driver_page.dart';

import 'auth_test_mocks.dart';

void main() {
  setUpAll(registerAuthUseCaseFallbackValues);

  testWidgets(
      'blocks submission with an inline error and never calls the cubit '
      'when only licenseNumber is filled in (no expiry date)', (tester) async {
    final registerDriver = MockRegisterDriver();
    final cubit = TestAuthCubit(registerDriver: registerDriver);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const RegisterDriverPage(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('driverFullNameField')), 'Jane Driver');
    await tester.enterText(find.byKey(const Key('driverEmailField')), 'jane@example.com');
    await tester.enterText(find.byKey(const Key('driverPasswordField')), 'password123');
    await tester.enterText(find.byKey(const Key('driverLicenseNumberField')), 'LIC-123');
    // licenseExpiryDate intentionally left unset.

    // The restyled form (Phase 6) is taller than the test viewport, so
    // scroll the submit button into view before tapping it.
    await tester.ensureVisible(find.byKey(const Key('driverSubmitButton')));
    await tester.tap(find.byKey(const Key('driverSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('License number and expiry date must be provided together.'),
      findsOneWidget,
    );
    verifyNever(() => registerDriver(any()));
  });
}
