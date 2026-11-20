import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/parent_repository.dart';

class SubmitLinkRequest implements UseCase<int, SubmitLinkRequestParams> {
  final ParentRepository repository;
  SubmitLinkRequest(this.repository);

  @override
  Future<Either<Failure, int>> call(SubmitLinkRequestParams params) {
    return repository.submitLinkRequest(params.studentCode);
  }
}

class SubmitLinkRequestParams extends Equatable {
  final String studentCode;
  const SubmitLinkRequestParams(this.studentCode);

  @override
  List<Object?> get props => [studentCode];
}
