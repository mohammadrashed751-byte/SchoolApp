import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsiveWidth(context, 28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'I am a...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: responsiveHeight(context, 32)),
              _RoleButton(
                roleKey: 'roleParentButton',
                icon: Icons.family_restroom,
                label: 'Parent',
                onTap: () => context.push(AppRoutes.registerParent),
              ),
              SizedBox(height: responsiveHeight(context, 16)),
              _RoleButton(
                roleKey: 'roleDriverButton',
                icon: Icons.directions_bus_filled_outlined,
                label: 'Driver',
                onTap: () => context.push(AppRoutes.registerDriver),
              ),
              SizedBox(height: responsiveHeight(context, 16)),
              _RoleButton(
                roleKey: 'roleSupervisorButton',
                icon: Icons.supervisor_account_outlined,
                label: 'Supervisor',
                onTap: () => context.push(AppRoutes.registerSupervisor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String roleKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleButton({
    required this.roleKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      key: Key(roleKey),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: responsiveWidth(context, 24)),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: responsiveWidth(context, 20)),
      ),
    );
  }
}
