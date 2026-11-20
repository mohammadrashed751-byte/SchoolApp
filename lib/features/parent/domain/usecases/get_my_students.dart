import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/linked_student.dart';
import '../repositories/parent_repository.dart';

class GetMyStudents implements UseCase<List<LinkedStudent>, NoParams> {
  final ParentRepository repository;
  GetMyStudents(this.repository);

  @override
  Future<Either<Failure, List<LinkedStudent>>> call(NoParams params) {
    return repository.getMyStudents();
  }
}
