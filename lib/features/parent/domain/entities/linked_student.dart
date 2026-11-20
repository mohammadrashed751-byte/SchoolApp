import 'package:equatable/equatable.dart';

class LinkedStudent extends Equatable {
  final int studentId;
  final String studentCode;
  final String fullName;
  final String gradeName;
  final DateTime linkedAtUtc;

  const LinkedStudent({
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    required this.gradeName,
    required this.linkedAtUtc,
  });

  @override
  List<Object?> get props => [studentId, studentCode, fullName, gradeName, linkedAtUtc];
}
