import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.userId,
    required super.email,
    required super.roleCode,
    required super.accountStatus,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        userId: json['userId'] as int,
        email: json['email'] as String,
        roleCode: json['roleCode'] as String,
        accountStatus: json['accountStatus'] as String,
      );
}
