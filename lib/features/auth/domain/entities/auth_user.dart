import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final int userId;
  final String email;
  final String roleCode;
  final String accountStatus;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.roleCode,
    required this.accountStatus,
  });

  @override
  List<Object?> get props => [userId, email, roleCode, accountStatus];
}
