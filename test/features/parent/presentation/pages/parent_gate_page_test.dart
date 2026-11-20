import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/parent/domain/entities/linked_student.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_app/features/parent/presentation/cubit/link_request_cubit.dart';
import 'package:flutter_app/features/parent/presentation/cubit/parent_gate_cubit.dart';
import 'package:flutter_app/features/parent/presentation/pages/parent_gate_page.dart';

import '../../../auth/presentation/pages/auth_test_mocks.dart';
import 'parent_test_mocks.dart';

Future<TestAuthCubit> _pumpParentGatePage(
  WidgetTester tester, {
  required MockGetMyStudents getMyStudents,
  required MockGetMyLinkRequests getMyLinkRequests,
  required MockSubmitLinkRequest submitLinkRequest,
  required MockLogout logout,
}) async {
  final authCubit = TestAuthCubit(logout: logout);
  addTearDown(authCubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<ParentGateCubit>(
            create: (_) => buildTestParentGateCubit(getMyStudents),
          ),
          BlocProvider<LinkRequestCubit>(
            create: (_) => buildTestLinkRequestCubit(
              submitLinkRequest: submitLinkRequest,
              getMyLinkRequests: getMyLinkRequests,
            ),
          ),
        ],
        child: const ParentGatePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return authCubit;
}

void main() {
  setUpAll(() {
    registerAuthUseCaseFallbackValues();
    registerParentUseCaseFallbackValues();
  });

  testWidgets(
      'logout button is visible in the NeedsStudentCode state and transitions '
      'AuthCubit to AuthUnauthenticated when tapped', (tester) async {
    final getMyStudents = MockGetMyStudents();
    when(() => getMyStudents(any())).thenAnswer((_) async => const Right([]));
    final getMyLinkRequests = MockGetMyLinkRequests();
    when(() => getMyLinkRequests(any())).thenAnswer((_) async => const Right([]));
    final logout = MockLogout();
    when(() => logout(any())).thenAnswer((_) async => const Right(unit));

    final authCubit = await _pumpParentGatePage(
      tester,
      getMyStudents: getMyStudents,
      getMyLinkRequests: getMyLinkRequests,
      submitLinkRequest: MockSubmitLinkRequest(),
      logout: logout,
    );

    // We're in NeedsStudentCode (empty student list).
    expect(find.byKey(const Key('submitStudentCodeButton')), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(authCubit.state, isA<AuthUnauthenticated>());
    verify(() => logout(any())).called(1);
  });

  testWidgets(
      'logout button is also visible in the HasStudents state and still works',
      (tester) async {
    final getMyStudents = MockGetMyStudents();
    when(() => getMyStudents(any())).thenAnswer(
      (_) async => Right([
        LinkedStudent(
          studentId: 1,
          studentCode: 'S-001',
          fullName: 'Kid One',
          gradeName: 'Grade 3',
          linkedAtUtc: DateTime.utc(2026, 1, 1),
        ),
      ]),
    );
    final getMyLinkRequests = MockGetMyLinkRequests();
    when(() => getMyLinkRequests(any())).thenAnswer((_) async => const Right([]));
    final logout = MockLogout();
    when(() => logout(any())).thenAnswer((_) async => const Right(unit));

    final authCubit = await _pumpParentGatePage(
      tester,
      getMyStudents: getMyStudents,
      getMyLinkRequests: getMyLinkRequests,
      submitLinkRequest: MockSubmitLinkRequest(),
      logout: logout,
    );

    expect(find.byKey(const Key('linkedStudentsList')), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(authCubit.state, isA<AuthUnauthenticated>());
  });
}
