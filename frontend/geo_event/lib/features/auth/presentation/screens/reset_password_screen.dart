import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.initialEmail,
    this.initialToken,
  });

  final String? initialEmail;
  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with AuthFeedback {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String get _hiddenToken => widget.initialToken?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_hiddenToken.isEmpty) {
      showAuthError(
        context,
        'This reset link is invalid or incomplete.',
        fallbackMessage: 'Missing reset token.',
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      showAuthError(
        context,
        'Email is missing from the reset link.',
        fallbackMessage: 'Missing email.',
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: _emailController.text.trim(),
            token: _hiddenToken,
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) return;

      showAuthSuccess(
        context,
        'Your password has been reset successfully.',
      );

      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      showAuthError(
        context,
        error,
        fallbackMessage: 'Failed to reset password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Reset Password',
      child: AuthFormCard(
        child: AbsorbPointer(
          absorbing: authState.isLoading,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuthHeader(
                  title: 'Create a new password',
                  subtitle:
                      'Enter your email and new password to finish the reset.',
                  icon: Icons.lock_reset_rounded,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                AuthPasswordField(
                  controller: _passwordController,
                  labelText: 'New Password',
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
                  labelText: 'Confirm New Password',
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  onToggleVisibility: () {
                    if (authState.isLoading) return;
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 20),
                AuthSubmitButton(
                  label: 'Reset Password',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}