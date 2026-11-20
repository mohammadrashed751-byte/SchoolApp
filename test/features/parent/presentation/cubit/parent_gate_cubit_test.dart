import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/features/parent/domain/entities/linked_student.dart';
import 'package:flutter_app/features/parent/presentation/cubit/parent_gate_cubit.dart';
import 'package:flutter_app/features/parent/presentation/state/parent_gate_state.dart';

import '../pages/parent_test_mocks.dart';

void main() {
  late MockGetMyStudents getMyStudents;

  final student = LinkedStudent(
    studentId: 1,
    studentCode: 'S-001',
    fullName: 'Kid One',
    gradeName: 'Grade 3',
    linkedAtUtc: DateTime.utc(2026, 1, 1),
  );

  setUpAll(registerParentUseCaseFallbackValues);

  setUp(() {
    getMyStudents = MockGetMyStudents();
  });

  blocTest<ParentGateCubit, ParentGateState>(
    'load() with an empty student list emits [Loading, NeedsStudentCode]',
    build: () => ParentGateCubit(getMyStudentsUseCase: getMyStudents),
    setUp: () => when(() => getMyStudents(any())).thenAnswer((_) async => const Right([])),
    act: (cubit) => cubit.load(),
    expect: () => [isA<ParentGateLoading>(), isA<ParentGateNeedsStudentCode>()],
  );

  blocTest<ParentGateCubit, ParentGateState>(
    'load() with a non-empty student list emits [Loading, HasStudents(list)]',
    build: () => ParentGateCubit(getMyStudentsUseCase: getMyStudents),
    setUp: () =>
        when(() => getMyStudents(any())).thenAnswer((_) async => Right([student])),
    act: (cubit) => cubit.load(),
    expect: () => [isA<ParentGateLoading>(), isA<ParentGateHasStudents>()],
    verify: (cubit) {
      expect((cubit.state as ParentGateHasStudents).students, [student]);
    },
  );

  blocTest<ParentGateCubit, ParentGateState>(
    'load() failure emits [Loading, Error(message)]',
    build: () => ParentGateCubit(getMyStudentsUseCase: getMyStudents),
    setUp: () => when(() => getMyStudents(any()))
        .thenAnswer((_) async => const Left(NetworkFailure('offline'))),
    act: (cubit) => cubit.load(),
    expect: () => [isA<ParentGateLoading>(), isA<ParentGateError>()],
    verify: (cubit) {
      expect((cubit.state as ParentGateError).message, 'offline');
    },
  );
}
