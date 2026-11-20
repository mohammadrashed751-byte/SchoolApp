import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/link_request.dart';
import '../repositories/parent_repository.dart';

class GetMyLinkRequests implements UseCase<List<LinkRequest>, NoParams> {
  final ParentRepository repository;
  GetMyLinkRequests(this.repository);

  @override
  Future<Either<Failure, List<LinkRequest>>> call(NoParams params) {
    return repository.getMyLinkRequests();
  }
}
