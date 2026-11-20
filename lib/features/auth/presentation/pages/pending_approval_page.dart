import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// Purely an explicit navigation destination (reached from the driver/
/// supervisor registration forms, left via the button below) — never an
/// automatic redirect target for the router.
class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending approval')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsiveWidth(context, 28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top_outlined,
                color: AppColors.accent,
                size: responsiveWidth(context, 64),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              Text(
                'Your account is awaiting administrator approval. '
                "You'll be able to log in once it has been approved.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: responsiveHeight(context, 28)),
              ElevatedButton(
                key: const Key('backToLoginButton'),
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
