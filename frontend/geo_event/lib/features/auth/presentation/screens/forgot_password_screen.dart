import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_message_card.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AuthFeedback {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authStateProvider.notifier)
          .forgotPassword(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      showAuthSuccess(
        context,
        'If an account exists for this email, a reset link has been sent. Check your inbox and spam folder.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _emailSent = false;
      });

      showAuthError(
        context,
        error,
        fallbackMessage: 'Failed to send the reset link. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Forgot Password',
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
                  title: 'Reset your password',
                  subtitle:
                      'Enter your email address and we will send you a reset link if an account exists.',
                  icon: Icons.lock_reset_rounded,
                ),
                if (_emailSent) ...[
                  const AuthMessageCard(
                    message:
                        'Check your email inbox and spam folder for reset instructions.',
                    icon: Icons.mark_email_read_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.email,
                  enabled: !authState.isLoading,
                  helperText: authState.isLoading
                      ? 'Sending reset instructions...'
                      : 'Enter the email address linked to your account.',
                ),
                const SizedBox(height: 20),
                AuthSubmitButton(
                  label: 'Send Reset Link',
                  isLoading: authState.isLoading,
                  disabledReason: 'Please wait while the reset link is being sent.',
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