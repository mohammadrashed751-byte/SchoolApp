import 'package:equatable/equatable.dart';

class LinkRequest extends Equatable {
  final int requestId;
  final String studentCode;
  final String studentFullName;
  final String status;
  final DateTime requestedAtUtc;
  final String? rejectionReason;

  const LinkRequest({
    required this.requestId,
    required this.studentCode,
    required this.studentFullName,
    required this.status,
    required this.requestedAtUtc,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        requestId,
        studentCode,
        studentFullName,
        status,
        requestedAtUtc,
        rejectionReason,
      ];
}
