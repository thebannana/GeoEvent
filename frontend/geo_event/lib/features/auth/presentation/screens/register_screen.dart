import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_controller.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Minimum 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[!@#\$%\^&\*\(\)_\+\-\=\[\]\{\};:\",\.<>\?\/\\|`~]')
        .hasMatch(password)) {
      return 'Add at least one special character';
    }
    return null;
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      debugPrint('========== REGISTER ERROR ==========');
      debugPrint('TYPE: ${error.type}');
      debugPrint('MESSAGE: ${error.message}');
      debugPrint('STATUS CODE: ${error.response?.statusCode}');
      debugPrint('RESPONSE DATA: ${error.response?.data}');
      debugPrint('REQUEST URI: ${error.requestOptions.uri}');
      debugPrint('REQUEST METHOD: ${error.requestOptions.method}');
      debugPrint('REQUEST DATA: ${error.requestOptions.data}');
      debugPrint('====================================');

      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return error.message ?? 'Registration failed.';
    }
    return 'Registration failed.';
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

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
        _birthDateController.text =
            '${date.day.toString().padLeft(2, '0')}.'
            '${date.month.toString().padLeft(2, '0')}.'
            '${date.year}';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birth date is required')),
      );
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept consent to continue')),
      );
      return;
    }

    try {
      final autoLoggedIn = await ref.read(authStateProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            birthDate: _selectedBirthDate!,
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            consentGiven: _consentGiven,
          );

      TextInput.finishAutofillContext();

      if (!mounted) return;

      if (autoLoggedIn) {
        context.go('/app');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully. Please log in.'),
          ),
        );
        context.go('/login');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final authState = ref.watch(authStateProvider);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('Register'),
      centerTitle: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AuthFormCard(
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
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 2) {
                          return 'First name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 2) {
                          return 'Last name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: authState.isLoading ? null : _pickBirthDate,
                      decoration: const InputDecoration(
                        labelText: 'Birth date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Birth date is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Confirm password is required';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _consentGiven,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _consentGiven = value ?? false;
                              });
                            },
                      title: const Text(
                        'I agree to the app consent and data usage',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Create Account'),
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
        ],
      ),
    ),
  );
}
}