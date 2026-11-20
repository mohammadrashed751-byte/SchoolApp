import '../../domain/entities/linked_student.dart';

class LinkedStudentModel extends LinkedStudent {
  const LinkedStudentModel({
    required super.studentId,
    required super.studentCode,
    required super.fullName,
    required super.gradeName,
    required super.linkedAtUtc,
  });

  factory LinkedStudentModel.fromJson(Map<String, dynamic> json) => LinkedStudentModel(
        studentId: json['studentId'] as int,
        studentCode: json['studentCode'] as String,
        fullName: json['fullName'] as String,
        gradeName: json['gradeName'] as String,
        linkedAtUtc: DateTime.parse(json['linkedAtUtc'] as String),
      );
}
