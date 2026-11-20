import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/link_request_model.dart';
import '../models/linked_student_model.dart';

abstract class ParentRemoteDataSource {
  Future<List<LinkedStudentModel>> getMyStudents();
  Future<List<LinkRequestModel>> getMyLinkRequests();
  Future<int> submitLinkRequest(String studentCode);
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  final ApiClient apiClient;
  ParentRemoteDataSourceImpl(this.apiClient);

  Dio get _dio => apiClient.dio;

  @override
  Future<List<LinkedStudentModel>> getMyStudents() async {
    final response = await _dio.get<List<dynamic>>(ApiConstants.parentStudents);
    return response.data!
        .map((json) => LinkedStudentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LinkRequestModel>> getMyLinkRequests() async {
    final response = await _dio.get<List<dynamic>>(ApiConstants.parentLinkRequests);
    return response.data!
        .map((json) => LinkRequestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> submitLinkRequest(String studentCode) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.parentLinkRequests,
      data: {'studentCode': studentCode},
    );
    return response.data as int;
  }
}
