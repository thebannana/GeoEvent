import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_consent_tile.dart';
import '../widgets/auth_date_field.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with AuthFeedback {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _consentGiven = false;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _selectedBirthDate ?? initialDate,
    );

    if (date == null) return;

    setState(() {
      _selectedBirthDate = date;
      _birthDateController.text =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final birthDateError = Validators.birthDate(
      _selectedBirthDate,
      minimumAge: 13,
    );

    if (birthDateError != null) {
      showAuthErrorMessage(context, birthDateError);
      return;
    }

    if (!_consentGiven) {
      showAuthErrorMessage(
        context,
        'You must accept consent to continue.',
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: _selectedBirthDate!,
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      consentGiven: _consentGiven,
    );

    TextInput.finishAutofillContext();

    if (!mounted) return;
    } catch (error) {
      if (!mounted) return;

      showAuthError(
        context,
        error,
        fallbackMessage: 'Registration failed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Register',
      child: AuthFormCard(
        child: AbsorbPointer(
          absorbing: authState.isLoading,
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(
                    title: 'Create your account',
                    subtitle:
                        'Join GeoEvent to discover events, manage your profile, and stay connected.',
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                  AuthTextField(
                    controller: _firstNameController,
                    labelText: 'First name',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    validator: Validators.firstName,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _lastNameController,
                    labelText: 'Last name',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.familyName],
                    validator: Validators.lastName,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.username],
                    validator: Validators.username,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _phoneController,
                    labelText: 'Phone number',
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: Validators.phoneNumber,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthDateField(
                    controller: _birthDateController,
                    labelText: 'Birth date',
                    onTap: _pickBirthDate,
                    validator: (_) => Validators.birthDate(
                      _selectedBirthDate,
                      minimumAge: 13,
                    ),
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onToggleVisibility: () {
                      if (authState.isLoading) return;
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: Validators.password,
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm password',
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    onToggleVisibility: () {
                      if (authState.isLoading) return;
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 12),
                  AuthConsentTile(
                    value: _consentGiven,
                    onChanged: authState.isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _consentGiven = value ?? false;
                            });
                          },
                    title: 'I agree to the app consent and data usage',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.push('/privacy'),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text('Read privacy policy'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: 'Create Account',
                    isLoading: authState.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}