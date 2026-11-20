import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/network/api_constants.dart';
import 'package:flutter_app/core/network/secure_token_storage.dart';
import 'package:flutter_app/core/network/token_manager.dart';
import 'package:flutter_app/core/network/unauthorized_session_exception.dart';

import 'fake_http_client_adapter.dart';

class MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

const _protectedPath = '/api/v1/some/protected';
const _oldRefreshToken = 'oldRefreshToken';
const _newRefreshToken = 'newRefreshToken';
const _newAccessToken = 'newAccessToken';

void main() {
  late TokenManager tokenManager;
  late MockSecureTokenStorage secureTokenStorage;
  late FakeHttpClientAdapter mainAdapter;
  late FakeHttpClientAdapter refreshAdapter;
  late ApiClient apiClient;

  setUp(() {
    tokenManager = TokenManager();
    secureTokenStorage = MockSecureTokenStorage();
    when(() => secureTokenStorage.readRefreshToken())
        .thenAnswer((_) async => _oldRefreshToken);
    when(() => secureTokenStorage.saveRefreshToken(any()))
        .thenAnswer((_) async {});
    when(() => secureTokenStorage.deleteRefreshToken())
        .thenAnswer((_) async {});
  });

  ApiClient buildClient({
    required FutureOr<ResponseBody> Function(RequestOptions) mainHandler,
    required FutureOr<ResponseBody> Function(RequestOptions) refreshHandler,
  }) {
    mainAdapter = FakeHttpClientAdapter(mainHandler);
    refreshAdapter = FakeHttpClientAdapter(refreshHandler);

    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
      ..httpClientAdapter = mainAdapter;
    final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
      ..httpClientAdapter = refreshAdapter;

    return ApiClient(
      tokenManager: tokenManager,
      secureTokenStorage: secureTokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );
  }

  ResponseBody successfulRefreshResponse(RequestOptions _) {
    return jsonResponseBody(
      jsonEncode({
        'accessToken': _newAccessToken,
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'refreshToken': _newRefreshToken,
      }),
      200,
    );
  }

  test('every outgoing request carries X-Client-Type: mobile', () async {
    apiClient = buildClient(
      mainHandler: (_) => jsonResponseBody('{}', 200),
      refreshHandler: successfulRefreshResponse,
    );

    await apiClient.dio.get('/api/v1/anything');

    expect(mainAdapter.requests.single.headers['X-Client-Type'], 'mobile');
  });

  test(
      'Authorization header is attached when an access token is set, '
      'and omitted when it is not',
      () async {
    apiClient = buildClient(
      mainHandler: (_) => jsonResponseBody('{}', 200),
      refreshHandler: successfulRefreshResponse,
    );

    await apiClient.dio.get('/api/v1/no-token');
    expect(mainAdapter.requests[0].headers.containsKey('Authorization'), isFalse);

    tokenManager.setAccessToken('someAccessToken', 3600);
    await apiClient.dio.get('/api/v1/with-token');
    expect(mainAdapter.requests[1].headers['Authorization'], 'Bearer someAccessToken');
  });

  test(
      '/auth/login and /auth/refresh never get the Authorization header, '
      'and a 401 on them never triggers the refresh interceptor',
      () async {
    apiClient = buildClient(
      mainHandler: (options) => jsonResponseBody('{}', 401),
      refreshHandler: successfulRefreshResponse,
    );

    tokenManager.setAccessToken('someAccessToken', 3600);

    await expectLater(
      apiClient.dio.post(ApiConstants.login, data: {}),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      apiClient.dio.post(ApiConstants.refresh, data: {}),
      throwsA(isA<DioException>()),
    );

    for (final request in mainAdapter.requests) {
      expect(request.headers.containsKey('Authorization'), isFalse);
    }
    expect(refreshAdapter.requests, isEmpty);
    verifyNever(() => secureTokenStorage.readRefreshToken());
  });

  test(
      'a 401 on a protected endpoint triggers exactly one /auth/refresh call '
      'and exactly one retry of the original request with the new token',
      () async {
    apiClient = buildClient(
      mainHandler: (options) {
        final authHeader = options.headers['Authorization'] as String?;
        if (authHeader == 'Bearer $_newAccessToken') {
          return jsonResponseBody('{"ok":true}', 200);
        }
        return jsonResponseBody('{}', 401);
      },
      refreshHandler: successfulRefreshResponse,
    );

    final response = await apiClient.dio.get(_protectedPath);

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(mainAdapter.requests.length, 2);
    expect(refreshAdapter.requests.length, 1);
  });

  test('on successful refresh, the new rotated refresh token is saved', () async {
    apiClient = buildClient(
      mainHandler: (options) {
        final authHeader = options.headers['Authorization'] as String?;
        if (authHeader == 'Bearer $_newAccessToken') {
          return jsonResponseBody('{"ok":true}', 200);
        }
        return jsonResponseBody('{}', 401);
      },
      refreshHandler: successfulRefreshResponse,
    );

    await apiClient.dio.get(_protectedPath);

    verify(() => secureTokenStorage.saveRefreshToken(_newRefreshToken)).called(1);
    expect(tokenManager.currentAccessToken, _newAccessToken);
  });

  test(
      'a failed refresh clears the session and propagates the error '
      'without retrying',
      () async {
    apiClient = buildClient(
      mainHandler: (_) => jsonResponseBody('{}', 401),
      refreshHandler: (_) => jsonResponseBody('{}', 401),
    );

    tokenManager.setAccessToken('staleAccessToken', 3600);

    DioException? caught;
    try {
      await apiClient.dio.get(_protectedPath);
    } on DioException catch (e) {
      caught = e;
    }

    expect(caught, isNotNull);
    expect(caught!.error, isA<UnauthorizedSessionException>());
    expect(mainAdapter.requests.length, 1, reason: 'no retry should happen');
    expect(refreshAdapter.requests.length, 1);
    expect(tokenManager.currentAccessToken, isNull);
    verify(() => secureTokenStorage.deleteRefreshToken()).called(1);
  });

  test(
      'concurrent 401s from parallel requests trigger only a single '
      '/auth/refresh call',
      () async {
    apiClient = buildClient(
      mainHandler: (options) {
        final authHeader = options.headers['Authorization'] as String?;
        if (authHeader == 'Bearer $_newAccessToken') {
          return jsonResponseBody('{"ok":true}', 200);
        }
        return jsonResponseBody('{}', 401);
      },
      refreshHandler: successfulRefreshResponse,
    );

    final responses = await Future.wait([
      apiClient.dio.get(_protectedPath),
      apiClient.dio.get(_protectedPath),
      apiClient.dio.get(_protectedPath),
    ]);

    for (final response in responses) {
      expect(response.statusCode, 200);
    }
    expect(refreshAdapter.requests.length, 1);
    expect(mainAdapter.requests.length, 6);
  });
}
