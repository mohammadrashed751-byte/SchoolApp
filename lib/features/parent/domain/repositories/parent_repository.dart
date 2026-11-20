import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/link_request.dart';
import '../entities/linked_student.dart';

abstract class ParentRepository {
  Future<Either<Failure, List<LinkedStudent>>> getMyStudents();

  Future<Either<Failure, List<LinkRequest>>> getMyLinkRequests();

  Future<Either<Failure, int>> submitLinkRequest(String studentCode);
}
