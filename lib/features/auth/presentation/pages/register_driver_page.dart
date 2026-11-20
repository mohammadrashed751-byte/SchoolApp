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

class RegisterDriverPage extends StatefulWidget {
  const RegisterDriverPage({super.key});

  @override
  State<RegisterDriverPage> createState() => _RegisterDriverPageState();
}

class _RegisterDriverPageState extends State<RegisterDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  DateTime? _licenseExpiryDate;
  String? _licensePairError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() => _licenseExpiryDate = picked);
    }
  }

  String? _validateLicensePair() {
    final hasLicenseNumber = _licenseNumberController.text.trim().isNotEmpty;
    final hasExpiryDate = _licenseExpiryDate != null;
    if (hasLicenseNumber != hasExpiryDate) {
      return 'License number and expiry date must be provided together.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final licensePairError = _validateLicensePair();
    setState(() => _licensePairError = licensePairError);
    if (licensePairError != null) return;

    final phoneNumber = _phoneNumberController.text.trim();
    final licenseNumber = _licenseNumberController.text.trim();

    context.read<AuthCubit>().registerDriver(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
          licenseNumber: licenseNumber.isEmpty ? null : licenseNumber,
          licenseExpiryDate: _licenseExpiryDate?.toIso8601String().split('T').first,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FlatAuthScaffold(
      title: 'Create a Driver account',
      subtitle: 'Drive routes and keep students on schedule',
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
                key: const Key('driverFullNameField'),
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: AppValidators.name,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('driverEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: AppValidators.email,
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('driverPhoneNumberField'),
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                // Optional per the backend's nullable phoneNumber field —
                // see the matching note in register_parent_page.dart.
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? null : AppValidators.phone(value),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              // licenseNumber has no AppValidators counterpart (its own
              // pairing rule with licenseExpiryDate below is a bespoke
              // business rule, left untouched).
              TextFormField(
                key: const Key('driverLicenseNumberField'),
                controller: _licenseNumberController,
                decoration: const InputDecoration(labelText: 'License Number (optional)'),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              InkWell(
                key: const Key('driverLicenseExpiryDateField'),
                borderRadius: BorderRadius.circular(responsiveWidth(context, 14)),
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'License Expiry Date (optional)',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _licenseExpiryDate == null
                        ? 'Not set'
                        : _licenseExpiryDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),
              SizedBox(height: responsiveHeight(context, 20)),
              TextFormField(
                key: const Key('driverPasswordField'),
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    key: const Key('driverPasswordVisibilityToggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: AppValidators.password,
              ),
              if (_licensePairError != null) ...[
                SizedBox(height: responsiveHeight(context, 10)),
                Text(
                  _licensePairError!,
                  key: const Key('licensePairError'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              SizedBox(height: responsiveHeight(context, 28)),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    key: const Key('driverSubmitButton'),
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
