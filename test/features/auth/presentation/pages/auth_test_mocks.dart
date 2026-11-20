import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/usecase/usecase.dart';
import 'package:flutter_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_app/features/auth/domain/usecases/login.dart';
import 'package:flutter_app/features/auth/domain/usecases/logout.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_driver.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_parent.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_supervisor.dart';
import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLogin extends Mock implements Login {}

class MockRegisterParent extends Mock implements RegisterParent {}

class MockRegisterDriver extends Mock implements RegisterDriver {}

class MockRegisterSupervisor extends Mock implements RegisterSupervisor {}

class MockLogout extends Mock implements Logout {}

void registerAuthUseCaseFallbackValues() {
  registerFallbackValue(NoParams());
  registerFallbackValue(const LoginParams(email: 'a@a.com', password: 'pw'));
  registerFallbackValue(
    const RegisterParentParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
  );
  registerFallbackValue(
    const RegisterDriverParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
  );
  registerFallbackValue(
    const RegisterSupervisorParams(fullName: 'n', email: 'a@a.com', password: 'pw'),
  );
}

/// A real [AuthCubit] whose use cases are all mocks (never stubbed unless a
/// test stubs them), plus [emitState] to drive its state directly for pages/
/// router tests that don't want to go through a real use-case call.
class TestAuthCubit extends AuthCubit {
  TestAuthCubit({
    MockGetCurrentUser? getCurrentUser,
    MockLogin? login,
    MockRegisterParent? registerParent,
    MockRegisterDriver? registerDriver,
    MockRegisterSupervisor? registerSupervisor,
    MockLogout? logout,
  }) : super(
          getCurrentUserUseCase: getCurrentUser ?? MockGetCurrentUser(),
          loginUseCase: login ?? MockLogin(),
          registerParentUseCase: registerParent ?? MockRegisterParent(),
          registerDriverUseCase: registerDriver ?? MockRegisterDriver(),
          registerSupervisorUseCase: registerSupervisor ?? MockRegisterSupervisor(),
          logoutUseCase: logout ?? MockLogout(),
        );

  void emitState(AuthState state) => emit(state);
}
