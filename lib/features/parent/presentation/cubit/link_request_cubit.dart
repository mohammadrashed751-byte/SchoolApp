import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_my_link_requests.dart';
import '../../domain/usecases/submit_link_request.dart';
import '../state/link_request_state.dart';

class LinkRequestCubit extends Cubit<LinkRequestState> {
  final SubmitLinkRequest submitLinkRequestUseCase;
  final GetMyLinkRequests getMyLinkRequestsUseCase;

  LinkRequestCubit({
    required this.submitLinkRequestUseCase,
    required this.getMyLinkRequestsUseCase,
  }) : super(LinkRequestIdle());

  Future<void> submit(String studentCode) async {
    emit(LinkRequestSubmitting());
    final result = await submitLinkRequestUseCase(SubmitLinkRequestParams(studentCode));
    result.fold(
      (failure) => emit(LinkRequestFailure(failure.message)),
      (requestId) => emit(LinkRequestSubmitted(requestId)),
    );
  }

  Future<void> loadMyRequests() async {
    final result = await getMyLinkRequestsUseCase(NoParams());
    result.fold(
      (failure) => emit(LinkRequestFailure(failure.message)),
      (requests) => emit(LinkRequestListLoaded(requests)),
    );
  }
}
