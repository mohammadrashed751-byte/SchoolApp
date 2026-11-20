import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/auth_token_model.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokenModel> login(String email, String password);
  Future<AuthTokenModel> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<AuthUserModel> getMe();

  Future<void> registerParent({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<void> registerDriver({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiryDate,
  });

  Future<void> registerSupervisor({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  AuthRemoteDataSourceImpl(this.apiClient);

  Dio get _dio => apiClient.dio;

  @override
  Future<AuthTokenModel> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthTokenModel.fromJson(response.data!);
  }

  @override
  Future<AuthTokenModel> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    return AuthTokenModel.fromJson(response.data!);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      ApiConstants.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  @override
  Future<AuthUserModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
    return AuthUserModel.fromJson(response.data!);
  }

  @override
  Future<void> registerParent({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.registerParent,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      },
    );
  }

  @override
  Future<void> registerDriver({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseExpiryDate,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.registerDriver,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'licenseNumber': licenseNumber,
        'licenseExpiryDate': licenseExpiryDate,
      },
    );
  }

  @override
  Future<void> registerSupervisor({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.registerSupervisor,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      },
    );
  }
}
