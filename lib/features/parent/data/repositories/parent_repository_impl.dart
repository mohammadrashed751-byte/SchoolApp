import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/link_request.dart';
import '../../domain/entities/linked_student.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_data_source.dart';

/// DioException -> Failure mapping mirrors Phase 2's AuthRepositoryImpl
/// pattern exactly (that file is frozen, so the logic is duplicated here
/// rather than extracted into a shared helper core/ doesn't yet have).
class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource remoteDataSource;
  ParentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LinkedStudent>>> getMyStudents() async {
    try {
      final students = await remoteDataSource.getMyStudents();
      return Right(students);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<LinkRequest>>> getMyLinkRequests() async {
    try {
      final requests = await remoteDataSource.getMyLinkRequests();
      return Right(requests);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> submitLinkRequest(String studentCode) async {
    try {
      final requestId = await remoteDataSource.submitLinkRequest(studentCode);
      return Right(requestId);
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    }
  }

  Failure _mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(e.message ?? 'Network error');
      default:
        break;
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e) ?? 'Unknown server error';

    if (statusCode == 401) {
      return UnauthorizedFailure(message);
    }
    if (statusCode == 404) {
      return ServerFailure(message.isEmpty ? 'Student not found.' : message);
    }
    if (statusCode == 409) {
      return ServerFailure(
        message.isEmpty ? 'A request for this student already exists.' : message,
      );
    }
    return ServerFailure(message);
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString());
        if (messages.isNotEmpty) return messages.join('; ');
      }

      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return e.message;
  }
}
