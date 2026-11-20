import '../../domain/entities/auth_user.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  AuthAuthenticated(this.user);
}

/// No active session. Covers both "never logged in" and "session could not
/// be restored at bootstrap", and is also what logout always settles on.
final class AuthUnauthenticated extends AuthState {}

/// A register call succeeded. Kept distinct from [AuthUnauthenticated]
/// rather than reused for it: registration never creates a session, but the
/// UI still needs to tell "you're not logged in yet" apart from "check your
/// email, your account was created" — collapsing them into one state would
/// force the UI to track *why* it's unauthenticated via some side channel.
final class AuthRegistrationSuccess extends AuthState {}

/// A login or register attempt failed. Distinct from the bootstrap's
/// [AuthUnauthenticated] result: this carries a message meant to be shown
/// to the user, and must not erase whatever state preceded the attempt.
final class AuthActionFailure extends AuthState {
  final String message;
  AuthActionFailure(this.message);
}
