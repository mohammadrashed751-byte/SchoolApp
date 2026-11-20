class TokenManager {
  String? _accessToken;
  DateTime? _expiry;

  String? get currentAccessToken => _accessToken;

  DateTime? get currentExpiry => _expiry;

  void setAccessToken(String token, int expiresInSeconds) {
    _accessToken = token;
    _expiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
  }

  void clear() {
    _accessToken = null;
    _expiry = null;
  }
}
