import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_my_students.dart';
import '../state/parent_gate_state.dart';

class ParentGateCubit extends Cubit<ParentGateState> {
  final GetMyStudents getMyStudentsUseCase;

  /// `load()` is triggered once from the owning page's `initState` (the same
  /// convention Phase 3's SplashPage uses for `AuthCubit.bootstrap()`), not
  /// from here — calling it both here and from `initState` would fire the
  /// request twice.
  ParentGateCubit({required this.getMyStudentsUseCase}) : super(ParentGateLoading());

  Future<void> load() async {
    emit(ParentGateLoading());
    final result = await getMyStudentsUseCase(NoParams());
    result.fold(
      (failure) => emit(ParentGateError(failure.message)),
      (students) => emit(
        students.isEmpty ? ParentGateNeedsStudentCode() : ParentGateHasStudents(students),
      ),
    );
  }
}
