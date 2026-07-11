import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with AuthFeedback {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).login(
            emailOrUsername: _emailOrUsernameController.text.trim(),
            password: _passwordController.text,
          );

      TextInput.finishAutofillContext();

      if (!mounted) return;
      context.go('/app');
    } catch (error, stackTrace) {
      if (!mounted) return;

      AppLogger.error(
        'Login failed.',
        tag: 'LoginScreen',
        error: error,
        stackTrace: stackTrace,
      );

      showAuthError(
        context,
        error,
        fallbackMessage: ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage:
              'Login failed. Please check your credentials and try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Login',
      showBackButton: false,
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
                    title: 'Welcome back',
                    subtitle:
                        'Log in with your email or username to continue using GeoEvent.',
                    icon: Icons.event_available_rounded,
                  ),
                  AuthTextField(
                    controller: _emailOrUsernameController,
                    labelText: 'Email or username',
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: (value) => Validators.requiredField(
                      value,
                      fieldName: 'Email or username',
                    ),
                    enabled: !authState.isLoading,
                    helperText: authState.isLoading
                        ? 'Login is in progress...'
                        : 'Use the email or username you registered with.',
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    onToggleVisibility: () {
                      if (authState.isLoading) return;
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) => Validators.requiredField(
                      value,
                      fieldName: 'Password',
                    ),
                    enabled: !authState.isLoading,
                    helperText: authState.isLoading
                        ? 'Please wait while we verify your account.'
                        : 'Enter your account password.',
                  ),
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: 'Login',
                    isLoading: authState.isLoading,
                    disabledReason:
                        'Please wait while your login request is being processed.',
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => context.push('/register'),
                    child: Text(
                      'Create account',
                    ),
                  ),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                    ),
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