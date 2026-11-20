class ApiConstants {
  static const String baseUrl =
      'https://headphone-jury-direction.ngrok-free.dev';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';
  static const String registerParent = '/api/v1/auth/register/parent';
  static const String registerDriver = '/api/v1/auth/register/driver';
  static const String registerSupervisor = '/api/v1/auth/register/supervisor';
  static const String parentStudents = '/api/v1/parent/students';
  static const String parentLinkRequests = '/api/v1/parent/link-requests';
}
