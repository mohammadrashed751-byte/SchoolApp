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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Cosmetic only, matching the reference design — there is no "remember
  // me" concept on the backend or in AuthCubit to wire this to; a session's
  // refresh token is always persisted regardless of this checkbox.
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _showNotAvailableYet(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature isn\'t available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlatAuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to track your school transport',
      form: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthActionFailure) {
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
                key: const Key('loginEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: AppValidators.email,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('loginPasswordField'),
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    key: const Key('loginPasswordVisibilityToggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                // Login only requires a non-empty password — it must
                // not enforce the minimum-length rule registration does.
                validator: AppValidators.loginPassword,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    key: const Key('rememberMeCheckbox'),
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: responsiveWidth(context, 22),
                          width: responsiveWidth(context, 22),
                          decoration: BoxDecoration(
                            color: _rememberMe ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(responsiveWidth(context, 5)),
                            border: Border.all(
                              color: _rememberMe ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: _rememberMe
                              ? Icon(
                                  Icons.check,
                                  size: responsiveWidth(context, 15),
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: responsiveWidth(context, 10)),
                        Text('Remember Me', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('forgotPasswordButton'),
                    onPressed: () => _showNotAvailableYet('Password reset'),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              SizedBox(height: responsiveHeight(context, 28)),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    key: const Key('loginSubmitButton'),
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
                        : const Text('Log in'),
                  );
                },
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: responsiveWidth(context, 14)),
                    child: Text('OR', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              // No Google OAuth is wired up on the backend — this button
              // matches the reference visually but is intentionally
              // non-functional (an honest "coming soon" message) rather
              // than faking a sign-in flow.
              OutlinedButton.icon(
                key: const Key('googleSignInButton'),
                onPressed: () => _showNotAvailableYet('Google sign-in'),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.pageBackground,
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide.none,
                  minimumSize: Size(double.infinity, responsiveHeight(context, 56)),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: responsiveWidth(context, 15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(responsiveWidth(context, 14)),
                  ),
                ),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    key: const Key('createAccountButton'),
                    onTap: () => context.push(AppRoutes.register),
                    child: Text(
                      'Create account',
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
