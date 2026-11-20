import '../../../../core/network/secure_token_storage.dart';
import '../../../../core/network/token_manager.dart';

/// Thin pass-through to the core session primitives. Owns no storage logic
/// of its own — `core/network` already owns that.
abstract class AuthLocalDataSource {
  Future<void> saveRefreshToken(String token);
  Future<String?> readRefreshToken();
  Future<void> deleteRefreshToken();
  void setAccessToken(String token, int expiresInSeconds);
  void clearAccessToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureTokenStorage secureTokenStorage;
  final TokenManager tokenManager;

  AuthLocalDataSourceImpl({
    required this.secureTokenStorage,
    required this.tokenManager,
  });

  @override
  Future<void> saveRefreshToken(String token) =>
      secureTokenStorage.saveRefreshToken(token);

  @override
  Future<String?> readRefreshToken() => secureTokenStorage.readRefreshToken();

  @override
  Future<void> deleteRefreshToken() => secureTokenStorage.deleteRefreshToken();

  @override
  void setAccessToken(String token, int expiresInSeconds) =>
      tokenManager.setAccessToken(token, expiresInSeconds);

  @override
  void clearAccessToken() => tokenManager.clear();
}
