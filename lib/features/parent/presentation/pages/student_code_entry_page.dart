import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../cubit/link_request_cubit.dart';
import '../cubit/parent_gate_cubit.dart';
import '../state/link_request_state.dart';

/// Shown in place on the `/parent` route (not navigated to separately) when
/// [ParentGateCubit] reports the parent has no approved student yet — it
/// needs the same `LinkRequestCubit`/`ParentGateCubit` pair that `/parent`'s
/// route already provides, so keeping it inline avoids re-providing them on
/// a second route.
class StudentCodeEntryPage extends StatefulWidget {
  const StudentCodeEntryPage({super.key});

  @override
  State<StudentCodeEntryPage> createState() => _StudentCodeEntryPageState();
}

class _StudentCodeEntryPageState extends State<StudentCodeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<LinkRequestCubit>().loadMyRequests();
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LinkRequestCubit>().submit(_studentCodeController.text.trim());
  }

  void _refresh() {
    context.read<LinkRequestCubit>().loadMyRequests();
    context.read<ParentGateCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LinkRequestCubit, LinkRequestState>(
      listener: (context, state) {
        if (state is LinkRequestSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted, waiting for school approval')),
          );
          _studentCodeController.clear();
          context.read<LinkRequestCubit>().loadMyRequests();
        }
      },
      // ListView is itself scrollable, so a taller keyboard just shrinks the
      // visible viewport instead of overflowing it — combined with the
      // Scaffold's default resizeToAvoidBottomInset in ParentGatePage, the
      // focused field is never left hidden behind the keyboard.
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: EdgeInsets.all(responsiveWidth(context, 20)),
          children: [
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsiveWidth(context, 18)),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: EdgeInsets.all(responsiveWidth(context, 20)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Link your child',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: responsiveHeight(context, 6)),
                      Text(
                        'Enter the student code your school gave you.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: responsiveHeight(context, 20)),
                      TextFormField(
                        key: const Key('studentCodeField'),
                        controller: _studentCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Student Code',
                          prefixIcon: Icon(Icons.qr_code_outlined),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Student code is required'
                            : null,
                      ),
                      SizedBox(height: responsiveHeight(context, 20)),
                      BlocBuilder<LinkRequestCubit, LinkRequestState>(
                        builder: (context, state) {
                          final isSubmitting = state is LinkRequestSubmitting;
                          return ElevatedButton(
                            key: const Key('submitStudentCodeButton'),
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
                                ? SizedBox(
                                    height: responsiveWidth(context, 18),
                                    width: responsiveWidth(context, 18),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textHint,
                                    ),
                                  )
                                : const Text('Link'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: responsiveHeight(context, 16)),
            TextButton.icon(
              key: const Key('refreshLinkRequestsButton'),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            SizedBox(height: responsiveHeight(context, 20)),
            BlocBuilder<LinkRequestCubit, LinkRequestState>(
              builder: (context, state) {
                if (state is LinkRequestFailure) {
                  return Text(
                    state.message,
                    key: const Key('linkRequestErrorText'),
                    style: const TextStyle(color: AppColors.error),
                  );
                }
                if (state is LinkRequestListLoaded) {
                  if (state.requests.isEmpty) {
                    return Text(
                      'No link requests yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: state.requests
                        .map(
                          (request) => Card(
                            elevation: 0,
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(responsiveWidth(context, 14)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            margin: EdgeInsets.only(bottom: responsiveHeight(context, 10)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: responsiveWidth(context, 16),
                                vertical: responsiveHeight(context, 4),
                              ),
                              key: Key('linkRequest_${request.requestId}'),
                              title: Text(
                                '${request.studentFullName} (${request.studentCode})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Text(
                                request.rejectionReason == null
                                    ? request.status
                                    : '${request.status}: ${request.rejectionReason}',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
