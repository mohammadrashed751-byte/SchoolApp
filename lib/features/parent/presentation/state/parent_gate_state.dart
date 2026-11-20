import '../../domain/entities/linked_student.dart';

sealed class ParentGateState {}

final class ParentGateLoading extends ParentGateState {}

final class ParentGateNeedsStudentCode extends ParentGateState {}

final class ParentGateHasStudents extends ParentGateState {
  final List<LinkedStudent> students;
  ParentGateHasStudents(this.students);
}

final class ParentGateError extends ParentGateState {
  final String message;
  ParentGateError(this.message);
}
