import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/linked_student.dart';
import '../cubit/parent_gate_cubit.dart';
import '../state/parent_gate_state.dart';
import 'student_code_entry_page.dart';

/// Route target for Parent. Branches on [ParentGateCubit]'s state:
/// - [ParentGateNeedsStudentCode] renders [StudentCodeEntryPage]'s content
///   in place, rather than navigating to it as a separate route — both need
///   the same `ParentGateCubit`/`LinkRequestCubit` pair this route already
///   provides once.
/// - [ParentGateHasStudents] renders a plain list (name/code/grade) inline;
///   this is intentionally a placeholder-with-real-data, not a full screen.
class ParentGatePage extends StatefulWidget {
  const ParentGatePage({super.key});

  @override
  State<ParentGatePage> createState() => _ParentGatePageState();
}

class _ParentGatePageState extends State<ParentGatePage> {
  @override
  void initState() {
    super.initState();
    context.read<ParentGateCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Parent'),
        actions: [
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ParentGateCubit, ParentGateState>(
          builder: (context, state) {
            if (state is ParentGateLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ParentGateNeedsStudentCode) {
              return const StudentCodeEntryPage();
            }
            if (state is ParentGateHasStudents) {
              return _StudentsList(students: state.students);
            }
            if (state is ParentGateError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(responsiveWidth(context, 28)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: responsiveWidth(context, 56),
                      ),
                      SizedBox(height: responsiveHeight(context, 16)),
                      Text(
                        state.message,
                        key: const Key('parentGateErrorText'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: responsiveHeight(context, 20)),
                      ElevatedButton(
                        key: const Key('parentGateRetryButton'),
                        onPressed: () => context.read<ParentGateCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StudentsList extends StatelessWidget {
  final List<LinkedStudent> students;
  const _StudentsList({required this.students});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('linkedStudentsList'),
      padding: EdgeInsets.all(responsiveWidth(context, 20)),
      itemCount: students.length,
      separatorBuilder: (_, _) => SizedBox(height: responsiveHeight(context, 12)),
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveWidth(context, 14)),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsiveWidth(context, 16),
              vertical: responsiveHeight(context, 8),
            ),
            key: Key('linkedStudent_${student.studentId}'),
            leading: CircleAvatar(
              radius: responsiveWidth(context, 22),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.school_outlined, color: Colors.white),
            ),
            title: Text(student.fullName, style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('${student.studentCode} — ${student.gradeName}'),
          ),
        );
      },
    );
  }
}
