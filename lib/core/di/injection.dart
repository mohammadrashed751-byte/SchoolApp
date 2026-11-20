import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register_driver.dart';
import '../../features/auth/domain/usecases/register_parent.dart';
import '../../features/auth/domain/usecases/register_supervisor.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/parent/data/datasources/parent_remote_data_source.dart';
import '../../features/parent/data/repositories/parent_repository_impl.dart';
import '../../features/parent/domain/repositories/parent_repository.dart';
import '../../features/parent/domain/usecases/get_my_link_requests.dart';
import '../../features/parent/domain/usecases/get_my_students.dart';
import '../../features/parent/domain/usecases/submit_link_request.dart';
import '../../features/parent/presentation/cubit/link_request_cubit.dart';
import '../../features/parent/presentation/cubit/parent_gate_cubit.dart';
import '../network/api_client.dart';
import '../network/secure_token_storage.dart';
import '../network/token_manager.dart';

final GetIt getIt = GetIt.instance;

Future<void> initCoreDependencies() async {
  getIt.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());

  getIt.registerLazySingleton<TokenManager>(() => TokenManager());

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenManager: getIt<TokenManager>(),
      secureTokenStorage: getIt<SecureTokenStorage>(),
    ),
  );

  _registerAuthFeature();
  _registerParentFeature();
}

void _registerAuthFeature() {
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureTokenStorage: getIt<SecureTokenStorage>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<Login>(() => Login(getIt<AuthRepository>()));
  getIt.registerLazySingleton<RegisterParent>(
    () => RegisterParent(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterDriver>(
    () => RegisterDriver(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterSupervisor>(
    () => RegisterSupervisor(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<Logout>(() => Logout(getIt<AuthRepository>()));
  getIt.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      getCurrentUserUseCase: getIt<GetCurrentUser>(),
      loginUseCase: getIt<Login>(),
      registerParentUseCase: getIt<RegisterParent>(),
      registerDriverUseCase: getIt<RegisterDriver>(),
      registerSupervisorUseCase: getIt<RegisterSupervisor>(),
      logoutUseCase: getIt<Logout>(),
    ),
  );
}

void _registerParentFeature() {
  getIt.registerLazySingleton<ParentRemoteDataSource>(
    () => ParentRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ParentRepository>(
    () => ParentRepositoryImpl(getIt<ParentRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetMyStudents>(
    () => GetMyStudents(getIt<ParentRepository>()),
  );
  getIt.registerLazySingleton<GetMyLinkRequests>(
    () => GetMyLinkRequests(getIt<ParentRepository>()),
  );
  getIt.registerLazySingleton<SubmitLinkRequest>(
    () => SubmitLinkRequest(getIt<ParentRepository>()),
  );

  // Factories, not singletons: these Cubits are scoped to a single visit of
  // the /parent route, not to the app's whole lifetime like AuthCubit.
  getIt.registerFactory<ParentGateCubit>(
    () => ParentGateCubit(getMyStudentsUseCase: getIt<GetMyStudents>()),
  );
  getIt.registerFactory<LinkRequestCubit>(
    () => LinkRequestCubit(
      submitLinkRequestUseCase: getIt<SubmitLinkRequest>(),
      getMyLinkRequestsUseCase: getIt<GetMyLinkRequests>(),
    ),
  );
}
