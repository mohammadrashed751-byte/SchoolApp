import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/features/parent/domain/entities/link_request.dart';
import 'package:flutter_app/features/parent/presentation/cubit/link_request_cubit.dart';
import 'package:flutter_app/features/parent/presentation/state/link_request_state.dart';

import '../pages/parent_test_mocks.dart';

void main() {
  late MockSubmitLinkRequest submitLinkRequest;
  late MockGetMyLinkRequests getMyLinkRequests;

  final request = LinkRequest(
    requestId: 10,
    studentCode: 'S-002',
    studentFullName: 'Kid Two',
    status: 'PENDING',
    requestedAtUtc: DateTime.utc(2026, 1, 1),
  );

  setUpAll(registerParentUseCaseFallbackValues);

  setUp(() {
    submitLinkRequest = MockSubmitLinkRequest();
    getMyLinkRequests = MockGetMyLinkRequests();
  });

  LinkRequestCubit buildCubit() => LinkRequestCubit(
        submitLinkRequestUseCase: submitLinkRequest,
        getMyLinkRequestsUseCase: getMyLinkRequests,
      );

  group('submit', () {
    blocTest<LinkRequestCubit, LinkRequestState>(
      'success emits [Submitting, Submitted(requestId)]',
      build: buildCubit,
      setUp: () =>
          when(() => submitLinkRequest(any())).thenAnswer((_) async => const Right(42)),
      act: (cubit) => cubit.submit('S-003'),
      expect: () => [isA<LinkRequestSubmitting>(), isA<LinkRequestSubmitted>()],
      verify: (cubit) {
        expect((cubit.state as LinkRequestSubmitted).requestId, 42);
      },
    );

    blocTest<LinkRequestCubit, LinkRequestState>(
      '404 (unknown code) emits [Submitting, Failure(message)]',
      build: buildCubit,
      setUp: () => when(() => submitLinkRequest(any())).thenAnswer(
        (_) async => const Left(ServerFailure('No student with that code exists.')),
      ),
      act: (cubit) => cubit.submit('UNKNOWN'),
      expect: () => [isA<LinkRequestSubmitting>(), isA<LinkRequestFailure>()],
      verify: (cubit) {
        expect((cubit.state as LinkRequestFailure).message, 'No student with that code exists.');
      },
    );

    blocTest<LinkRequestCubit, LinkRequestState>(
      '409 (duplicate request) emits a distinguishable Failure message',
      build: buildCubit,
      setUp: () => when(() => submitLinkRequest(any())).thenAnswer(
        (_) async => const Left(ServerFailure('A request for this student already exists.')),
      ),
      act: (cubit) => cubit.submit('S-004'),
      expect: () => [isA<LinkRequestSubmitting>(), isA<LinkRequestFailure>()],
      verify: (cubit) {
        expect(
          (cubit.state as LinkRequestFailure).message,
          'A request for this student already exists.',
        );
      },
    );
  });

  group('loadMyRequests', () {
    blocTest<LinkRequestCubit, LinkRequestState>(
      'success emits [ListLoaded(requests)]',
      build: buildCubit,
      setUp: () => when(() => getMyLinkRequests(any()))
          .thenAnswer((_) async => Right([request])),
      act: (cubit) => cubit.loadMyRequests(),
      expect: () => [isA<LinkRequestListLoaded>()],
      verify: (cubit) {
        expect((cubit.state as LinkRequestListLoaded).requests, [request]);
      },
    );
  });
}
