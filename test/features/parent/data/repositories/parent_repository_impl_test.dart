import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/error/failure.dart';
import 'package:flutter_app/features/parent/data/datasources/parent_remote_data_source.dart';
import 'package:flutter_app/features/parent/data/models/link_request_model.dart';
import 'package:flutter_app/features/parent/data/models/linked_student_model.dart';
import 'package:flutter_app/features/parent/data/repositories/parent_repository_impl.dart';

class MockParentRemoteDataSource extends Mock implements ParentRemoteDataSource {}

DioException _badResponse(String path, int statusCode, {Object? data}) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: requestOptions, statusCode: statusCode, data: data),
  );
}

void main() {
  late MockParentRemoteDataSource remote;
  late ParentRepositoryImpl repository;

  final linkedAt = DateTime.utc(2026, 1, 1);
  final student = LinkedStudentModel(
    studentId: 1,
    studentCode: 'S-001',
    fullName: 'Kid One',
    gradeName: 'Grade 3',
    linkedAtUtc: linkedAt,
  );
  final linkRequest = LinkRequestModel(
    requestId: 10,
    studentCode: 'S-002',
    studentFullName: 'Kid Two',
    status: 'PENDING',
    requestedAtUtc: linkedAt,
  );

  setUp(() {
    remote = MockParentRemoteDataSource();
    repository = ParentRepositoryImpl(remote);
  });

  group('getMyStudents', () {
    test('empty list is returned as Right([])', () async {
      when(() => remote.getMyStudents()).thenAnswer((_) async => []);

      final result = await repository.getMyStudents();

      expect(
        result.fold((_) => null, (students) => students),
        isEmpty,
      );
    });

    test('non-empty list is returned as Right(list)', () async {
      when(() => remote.getMyStudents()).thenAnswer((_) async => [student]);

      final result = await repository.getMyStudents();

      expect(
        result.fold((_) => null, (students) => students),
        [student],
      );
    });
  });

  test('getMyLinkRequests success returns Right(list)', () async {
    when(() => remote.getMyLinkRequests()).thenAnswer((_) async => [linkRequest]);

    final result = await repository.getMyLinkRequests();

    expect(
      result.fold((_) => null, (requests) => requests),
      [linkRequest],
    );
  });

  group('submitLinkRequest', () {
    test('success returns Right(requestId)', () async {
      when(() => remote.submitLinkRequest('S-003')).thenAnswer((_) async => 42);

      final result = await repository.submitLinkRequest('S-003');

      expect(result, const Right<Failure, dynamic>(42));
    });

    test('404 maps to a ServerFailure with the ProblemDetails detail message', () async {
      when(() => remote.submitLinkRequest('UNKNOWN')).thenThrow(
        _badResponse(
          '/api/v1/parent/link-requests',
          404,
          data: {'detail': 'No student with that code exists.'},
        ),
      );

      final result = await repository.submitLinkRequest('UNKNOWN');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'No student with that code exists.');
        },
        (_) => fail('expected a Left'),
      );
    });

    test('409 maps to a ServerFailure distinguishable from the 404 case', () async {
      when(() => remote.submitLinkRequest('S-004')).thenThrow(
        _badResponse(
          '/api/v1/parent/link-requests',
          409,
          data: {'detail': 'A request for this student already exists.'},
        ),
      );

      final result = await repository.submitLinkRequest('S-004');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'A request for this student already exists.');
        },
        (_) => fail('expected a Left'),
      );
    });
  });
}
