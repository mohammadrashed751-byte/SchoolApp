import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/parent/presentation/cubit/link_request_cubit.dart';
import 'features/parent/presentation/cubit/parent_gate_cubit.dart';

Future<void> main() async {
  await initCoreDependencies();
  runApp(const SmartSchoolTransportApp());
}

class SmartSchoolTransportApp extends StatefulWidget {
  const SmartSchoolTransportApp({super.key});

  @override
  State<SmartSchoolTransportApp> createState() => _SmartSchoolTransportAppState();
}

class _SmartSchoolTransportAppState extends State<SmartSchoolTransportApp> {
  late final AuthCubit _authCubit = getIt<AuthCubit>();
  late final GoRouter _router = buildAppRouter(
    _authCubit,
    createParentGateCubit: () => getIt<ParentGateCubit>(),
    createLinkRequestCubit: () => getIt<LinkRequestCubit>(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: _authCubit,
      child: MaterialApp.router(
        routerConfig: _router,
        theme: AppTheme.light(context),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
