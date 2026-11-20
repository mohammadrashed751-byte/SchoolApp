import '../../domain/entities/link_request.dart';

class LinkRequestModel extends LinkRequest {
  const LinkRequestModel({
    required super.requestId,
    required super.studentCode,
    required super.studentFullName,
    required super.status,
    required super.requestedAtUtc,
    super.rejectionReason,
  });

  factory LinkRequestModel.fromJson(Map<String, dynamic> json) => LinkRequestModel(
        requestId: json['requestId'] as int,
        studentCode: json['studentCode'] as String,
        studentFullName: json['studentFullName'] as String,
        status: json['status'] as String,
        requestedAtUtc: DateTime.parse(json['requestedAtUtc'] as String),
        rejectionReason: json['rejectionReason'] as String?,
      );
}
