// Phase 5 Part B: simulated "app restart" session-persistence test.
//
// Why this lives in test/integration/ rather than the `integration_test`
// package: the project has no existing `integration_test/` convention, and
// this check needs neither a widget tree nor a connected device/emulator —
// it wires real ApiClient/AuthRepositoryImpl/AuthCubit instances together
// and drives them with plain `flutter_test`, which is enough to prove the
// cross-feature behavior Part B asks for.
//
// What's real vs. faked, and why: reaching a live .NET backend from this
// automated test isn't feasible in this environment (no backend URL/port
// was available here — see Part C's report), so the HTTP layer is a fake
// Dio [HttpClientAdapter] returning realistic login/refresh/me JSON
// payloads, exactly as Phase 1's api_client_test.dart already does.
// Everything above the HTTP layer — ApiClient's interceptors, TokenManager,
// SecureTokenStorage, AuthRepositoryImpl, AuthCubit — is the real production
// code, not mocks.
//
// SecureTokenStorage wraps the real `flutter_secure_storage` package (not a
// mocktail mock of our own wrapper), backed by that package's own official
// test support (`FlutterSecureStorage.setMockInitialValues`) instead of a
// real OS keychain, which isn't available in this test environment either.
// Per the task's own instruction, the SAME `SecureTokenStorage` instance is
// reused across "session 1" and "session 2" below — that instance (and the
// mocked platform backend underneath it) is what stands in for "the OS
// keychain surviving an app restart". Everything else (TokenManager,
// ApiClient, the Dio instances, AuthRepositoryImpl, AuthCubit) is thrown
// away and rebuilt from scratch for session 2, exactly like a cold start.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/network/secure_token_storage.dart';
import 'package:flutter_app/core/network/token_manager.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_app/features/auth/domain/usecases/login.dart';
import 'package:flutter_app/features/auth/domain/usecases/logout.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_driver.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_parent.dart';
import 'package:flutter_app/features/auth/domain/usecases/register_supervisor.dart';
import 'package:flutter_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/auth/presentation/state/auth_state.dart';

import '../core/network/fake_http_client_adapter.dart';

/// Wires one complete, real auth stack (ApiClient -> data sources ->
/// repository -> use cases -> AuthCubit), with the HTTP layer faked. Each
/// call to this builds a fully independent set of objects, except for
/// [secureTokenStorage], which the caller passes in and may reuse.
///
/// Both `login`/`me`/`refresh` calls made by [AuthRepositoryImpl] (via
/// [AuthRemoteDataSourceImpl]) go through the ApiClient's single public
/// `dio` — not through its separate internal refresh-only Dio, which only
/// backs ApiClient's own reactive 401 interceptor and isn't exercised by
/// this explicit-bootstrap flow. So there's just one fake adapter here.
class _AuthStack {
  final TokenManager tokenManager;
  final FakeHttpClientAdapter adapter;
  final AuthRepository repository;
  final AuthCubit authCubit;

  _AuthStack({
    required this.tokenManager,
    required this.adapter,
    required this.repository,
    required this.authCubit,
  });
}

_AuthStack _buildAuthStack({
  required SecureTokenStorage secureTokenStorage,
  required FutureOr<ResponseBody> Function(RequestOptions options) handler,
}) {
  final tokenManager = TokenManager();
  final adapter = FakeHttpClientAdapter(handler);

  final dio = Dio()..httpClientAdapter = adapter;

  final apiClient = ApiClient(
    tokenManager: tokenManager,
    secureTokenStorage: secureTokenStorage,
    dio: dio,
  );

  final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final localDataSource = AuthLocalDataSourceImpl(
    secureTokenStorage: secureTokenStorage,
    tokenManager: tokenManager,
  );
  final repository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  final authCubit = AuthCubit(
    getCurrentUserUseCase: GetCurrentUser(repository),
    loginUseCase: Login(repository),
    registerParentUseCase: RegisterParent(repository),
    registerDriverUseCase: RegisterDriver(repository),
    registerSupervisorUseCase: RegisterSupervisor(repository),
    logoutUseCase: Logout(repository),
  );

  return _AuthStack(
    tokenManager: tokenManager,
    adapter: adapter,
    repository: repository,
    authCubit: authCubit,
  );
}

ResponseBody _tokenResponse({
  required String accessToken,
  required String refreshToken,
}) {
  return jsonResponseBody(
    jsonEncode({
      'accessToken': accessToken,
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'refreshToken': refreshToken,
    }),
    200,
  );
}

ResponseBody _meResponse() {
  return jsonResponseBody(
    jsonEncode({
      'userId': 1,
      'email': 'parent@example.com',
      'roleCode': 'Parent',
      'accountStatus': 'ACTIVE',
    }),
    200,
  );
}

void main() {
  test(
      'a fresh TokenManager + AuthCubit, reading the SAME persisted refresh '
      'token, reaches AuthAuthenticated via bootstrap() alone (no login()) '
      'and rotates the stored refresh token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final secureTokenStorage = SecureTokenStorage();

    // ---------------------------------------------------------------
    // "Session 1": a real login, to put a refresh token into storage.
    // ---------------------------------------------------------------
    final session1 = _buildAuthStack(
      secureTokenStorage: secureTokenStorage,
      handler: (options) {
        if (options.path == '/api/v1/auth/login') {
          return _tokenResponse(accessToken: 'access-v1', refreshToken: 'refresh-v1');
        }
        if (options.path == '/api/v1/auth/me') {
          return _meResponse();
        }
        return jsonResponseBody('{}', 404);
      },
    );

    await session1.authCubit.login('parent@example.com', 'secret123');

    expect(session1.authCubit.state, isA<AuthAuthenticated>());
    expect(await secureTokenStorage.readRefreshToken(), 'refresh-v1');

    await session1.authCubit.close();
    // session1's TokenManager/ApiClient/AuthCubit are discarded here, same
    // as a killed process — only secureTokenStorage survives below.

    // ---------------------------------------------------------------
    // "Session 2": brand-new TokenManager/ApiClient/AuthCubit, but the
    // SAME SecureTokenStorage instance (the persisted refresh token).
    // ---------------------------------------------------------------
    final session2 = _buildAuthStack(
      secureTokenStorage: secureTokenStorage,
      handler: (options) {
        if (options.path == '/api/v1/auth/refresh') {
          // Only ever reached with the refresh token session 1 persisted.
          final body = options.data as Map<String, dynamic>;
          expect(body['refreshToken'], 'refresh-v1');
          return _tokenResponse(accessToken: 'access-v2', refreshToken: 'refresh-v2');
        }
        if (options.path == '/api/v1/auth/me') {
          return _meResponse();
        }
        return jsonResponseBody('{}', 404);
      },
    );

    expect(session2.tokenManager.currentAccessToken, isNull,
        reason: 'session 2 starts with a cold, empty in-memory token, like a real relaunch');

    await session2.authCubit.bootstrap();

    expect(session2.authCubit.state, isA<AuthAuthenticated>());
    expect(
      session2.adapter.requests.where((r) => r.path == '/api/v1/auth/refresh'),
      hasLength(1),
    );
    expect(
      session2.adapter.requests.where((r) => r.path == '/api/v1/auth/login'),
      isEmpty,
      reason: 'the session is restored from the persisted refresh token alone, no login() call',
    );

    final rotatedRefreshToken = await secureTokenStorage.readRefreshToken();
    expect(rotatedRefreshToken, 'refresh-v2');
    expect(rotatedRefreshToken, isNot('refresh-v1'));

    await session2.authCubit.close();
  });
}
