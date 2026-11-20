import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register_driver.dart';
import '../../domain/usecases/register_parent.dart';
import '../../domain/usecases/register_supervisor.dart';
import '../state/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final GetCurrentUser getCurrentUserUseCase;
  final Login loginUseCase;
  final RegisterParent registerParentUseCase;
  final RegisterDriver registerDriverUseCase;
  final RegisterSupervisor registerSupervisorUseCase;
  final Logout logoutUseCase;

  AuthCubit({
    required this.getCurrentUserUseCase,
    required this.loginUseCase,
    required this.registerParentUseCase,
    required this.registerDriverUseCase,
    required this.registerSupervisorUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial());

  Future<void> bootstrap() async {
    emit(AuthLoading());
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthActionFailure(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> registerParent({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    emit(AuthLoading());
    final result = await registerParentUseCase(
      RegisterParentParams(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      ),
    );
    result.fold(
      (failure) => emit(AuthActionFailure(failure.message)),
      (_) => emit(AuthRegistrationSuccess()),
    );
  }

  Future<void> registerDriver({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiryDate,
  }) async {
    emit(AuthLoading());
    final result = await registerDriverUseCase(
      RegisterDriverParams(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
      ),
    );
    result.fold(
      (failure) => emit(AuthActionFailure(failure.message)),
      (_) => emit(AuthRegistrationSuccess()),
    );
  }

  Future<void> registerSupervisor({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    emit(AuthLoading());
    final result = await registerSupervisorUseCase(
      RegisterSupervisorParams(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      ),
    );
    result.fold(
      (failure) => emit(AuthActionFailure(failure.message)),
      (_) => emit(AuthRegistrationSuccess()),
    );
  }

  Future<void> logout() async {
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }
}
