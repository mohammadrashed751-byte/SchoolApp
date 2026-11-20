import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'secure_token_storage.dart';
import 'token_manager.dart';
import 'unauthorized_session_exception.dart';

const _unauthenticatedPaths = <String>[
  ApiConstants.login,
  ApiConstants.refresh,
];

class ApiClient {
  final TokenManager _tokenManager;
  final SecureTokenStorage _secureTokenStorage;
  final Dio dio;

  /// Separate, interceptor-free Dio used only to call /auth/refresh, so the
  /// refresh call itself never re-triggers this client's 401 handling.
  final Dio _refreshDio;

  Future<String?>? _inFlightRefresh;

  ApiClient({
    required TokenManager tokenManager,
    required SecureTokenStorage secureTokenStorage,
    Dio? dio,
    Dio? refreshDio,
  })  : _tokenManager = tokenManager,
        _secureTokenStorage = secureTokenStorage,
        dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)),
        _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: _onRequest,
            onError: _onError,
          ),
        );
  }

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['X-Client-Type'] = 'mobile';

    final accessToken = _tokenManager.currentAccessToken;
    if (accessToken != null && !_unauthenticatedPaths.contains(options.path)) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestPath = err.requestOptions.path;
    final isUnauthenticatedEndpoint = _unauthenticatedPaths.contains(requestPath);

    if (err.response?.statusCode != 401 || isUnauthenticatedEndpoint) {
      handler.next(err);
      return;
    }

    final storedRefreshToken = await _secureTokenStorage.readRefreshToken();
    if (storedRefreshToken == null) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken(storedRefreshToken);

    if (newAccessToken == null) {
      handler.reject(
        err.copyWith(
          error: const UnauthorizedSessionException(),
        ),
      );
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Ensures only one /auth/refresh network call is in flight at a time;
  /// concurrent callers await the same [Future].
  Future<String?> _refreshAccessToken(String refreshToken) {
    _inFlightRefresh ??= _performRefresh(refreshToken).whenComplete(() {
      _inFlightRefresh = null;
    });
    return _inFlightRefresh!;
  }

  Future<String?> _performRefresh(String refreshToken) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'X-Client-Type': 'mobile'}),
      );

      final data = response.data!;
      final newAccessToken = data['accessToken'] as String;
      final expiresIn = data['expiresIn'] as int;
      final newRefreshToken = data['refreshToken'] as String;

      _tokenManager.setAccessToken(newAccessToken, expiresIn);
      await _secureTokenStorage.saveRefreshToken(newRefreshToken);

      return newAccessToken;
    } catch (_) {
      _tokenManager.clear();
      await _secureTokenStorage.deleteRefreshToken();
      return null;
    }
  }
}
