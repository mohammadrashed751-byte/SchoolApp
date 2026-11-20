/// Parses the AccessTokenDto shape returned by /auth/login and
/// /auth/refresh. Stays inside the data layer: domain never sees raw
/// tokens, only the [AuthUser] the repository derives from them.
class AuthTokenModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String refreshToken;

  const AuthTokenModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      AuthTokenModel(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        expiresIn: json['expiresIn'] as int,
        refreshToken: json['refreshToken'] as String,
      );
}
