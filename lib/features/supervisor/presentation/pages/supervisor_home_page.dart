import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Static placeholder — Supervisor has no real logic yet. Future phases
/// fill this in.
class SupervisorHomePage extends StatelessWidget {
  const SupervisorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(responsiveWidth(context, 28)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: responsiveWidth(context, 40),
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.supervisor_account_outlined,
                    color: Colors.white,
                    size: responsiveWidth(context, 38),
                  ),
                ),
                SizedBox(height: responsiveHeight(context, 20)),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final email = state is AuthAuthenticated ? state.user.email : '';
                    return Text(
                      'Supervisor — $email',
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  },
                ),
                SizedBox(height: responsiveHeight(context, 28)),
                ElevatedButton(
                  key: const Key('logoutButton'),
                  onPressed: () => context.read<AuthCubit>().logout(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
