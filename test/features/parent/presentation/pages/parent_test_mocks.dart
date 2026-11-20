import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/usecase/usecase.dart';
import 'package:flutter_app/features/parent/domain/usecases/get_my_link_requests.dart';
import 'package:flutter_app/features/parent/domain/usecases/get_my_students.dart';
import 'package:flutter_app/features/parent/domain/usecases/submit_link_request.dart';
import 'package:flutter_app/features/parent/presentation/cubit/link_request_cubit.dart';
import 'package:flutter_app/features/parent/presentation/cubit/parent_gate_cubit.dart';

class MockGetMyStudents extends Mock implements GetMyStudents {}

class MockGetMyLinkRequests extends Mock implements GetMyLinkRequests {}

class MockSubmitLinkRequest extends Mock implements SubmitLinkRequest {}

void registerParentUseCaseFallbackValues() {
  registerFallbackValue(NoParams());
  registerFallbackValue(const SubmitLinkRequestParams('code'));
}

ParentGateCubit buildTestParentGateCubit(MockGetMyStudents getMyStudents) {
  return ParentGateCubit(getMyStudentsUseCase: getMyStudents);
}

LinkRequestCubit buildTestLinkRequestCubit({
  required MockSubmitLinkRequest submitLinkRequest,
  required MockGetMyLinkRequests getMyLinkRequests,
}) {
  return LinkRequestCubit(
    submitLinkRequestUseCase: submitLinkRequest,
    getMyLinkRequestsUseCase: getMyLinkRequests,
  );
}
