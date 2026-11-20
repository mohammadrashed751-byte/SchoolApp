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

class RegisterParentPage extends StatefulWidget {
  const RegisterParentPage({super.key});

  @override
  State<RegisterParentPage> createState() => _RegisterParentPageState();
}

class _RegisterParentPageState extends State<RegisterParentPage> {
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
    context.read<AuthCubit>().registerParent(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FlatAuthScaffold(
      title: 'Create a Parent account',
      subtitle: 'Track your child\'s school transport',
      form: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created — you can log in now.'),
              ),
            );
            context.go(AppRoutes.login);
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
                key: const Key('parentFullNameField'),
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: AppValidators.name,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('parentEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: AppValidators.email,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('parentPhoneNumberField'),
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                // The backend's phoneNumber field is nullable/optional, so
                // this field must stay optional — AppValidators.phone
                // always requires a value, so it's only applied once
                // something has actually been typed, to still catch a
                // malformed number.
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? null : AppValidators.phone(value),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('parentPasswordField'),
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    key: const Key('parentPasswordVisibilityToggle'),
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
                    key: const Key('parentSubmitButton'),
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
