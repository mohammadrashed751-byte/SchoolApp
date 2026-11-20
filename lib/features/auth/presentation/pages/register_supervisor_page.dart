import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/responsive.dart';
import '../cubit/auth_cubit.dart';
import '../state/auth_state.dart';
import '../widgets/flat_auth_scaffold.dart';

class RegisterSupervisorPage extends StatefulWidget {
  const RegisterSupervisorPage({super.key});

  @override
  State<RegisterSupervisorPage> createState() => _RegisterSupervisorPageState();
}

class _RegisterSupervisorPageState extends State<RegisterSupervisorPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final phoneNumber = _phoneNumberController.text.trim();
    context.read<AuthCubit>().registerSupervisor(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FlatAuthScaffold(
      title: 'Create a Supervisor account',
      subtitle: 'Oversee routes and keep students safe',
      form: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistrationSuccess) {
            context.go(AppRoutes.pendingApproval);
          } else if (state is AuthActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('supervisorFullNameField'),
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: AppValidators.name,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('supervisorEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: AppValidators.email,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('supervisorPhoneNumberField'),
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                // Optional per the backend's nullable phoneNumber field —
                // see the matching note in register_parent_page.dart.
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? null : AppValidators.phone(value),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('supervisorPasswordField'),
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    key: const Key('supervisorPasswordVisibilityToggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: AppValidators.password,
              ),
              SizedBox(height: responsiveHeight(context, 28)),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    key: const Key('supervisorSubmitButton'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? SizedBox(
                            height: responsiveWidth(context, 18),
                            width: responsiveWidth(context, 18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Text('Create account'),
                  );
                },
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    key: const Key('backToLoginLink'),
                    onTap: () => context.go(AppRoutes.login),
                    child: Text(
                      'Login',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
