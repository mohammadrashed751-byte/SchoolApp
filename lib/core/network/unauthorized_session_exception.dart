/// Thrown (wrapped inside a [DioException]'s `error`) when a 401 could not be
/// recovered via refresh, so callers can distinguish an unrecoverable session
/// loss from a generic network/server error.
class UnauthorizedSessionException implements Exception {
  final String message;
  const UnauthorizedSessionException([this.message = 'Session expired']);

  @override
  String toString() => 'UnauthorizedSessionException: $message';
}
