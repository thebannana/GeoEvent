import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../application/auth_controller.dart';

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

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetCompleted = false;

  String get _hiddenToken => widget.initialToken?.trim() ?? '';

  bool get _hasValidResetPayload =>
      _hiddenToken.isNotEmpty && _emailController.text.trim().isNotEmpty;

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

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Email address is required.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'New password is required.';
    }

    if (text.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Please confirm the new password.';
    }

    if (text != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_hasValidResetPayload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This password reset link is invalid or incomplete. Request a new reset email and try again.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: _emailController.text.trim(),
            token: _hiddenToken,
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) return;

      setState(() {
        _resetCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your password has been reset successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = switch (error) {
        AppException e => e.message,
        _ =>
          'Failed to reset the password. Please request a new reset link and try again.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0x26000000)
                        : const Color(0x14000000),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _resetCompleted
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/geoevent.png',
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password reset complete',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your password was changed successfully. You can now return to the login screen and sign in with your new password.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.success.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: colors.success,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'The reset link has been used successfully. For security, use the latest email if you ever need to reset the password again.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppThemeMetrics.radiusMd + 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Back to login',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : !_hasValidResetPayload
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.go('/forgot-password'),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to forgot password'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Image.asset(
                              'assets/images/geoevent.png',
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Reset link invalid',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'This password reset link is missing required information or was opened incorrectly.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.warning.withValues(alpha: 0.34),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: colors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Go back to the forgot password screen, request a new email, and open the latest reset link.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : AbsorbPointer(
                          absorbing: isLoading,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.go('/login'),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Back to login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Image.asset(
                                  'assets/images/geoevent.png',
                                  height: 36,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Reset Password',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Enter your email and new password to complete the reset for the administrator account.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const _ResetFieldLabel('Email address'),
                                const SizedBox(height: 8),
                                _ResetTextField(
                                  controller: _emailController,
                                  hintText: 'Enter your admin email',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  enabled: !isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: _validateEmail,
                                  helperText: isLoading
                                      ? 'Reset request is being processed...'
                                      : 'This email should match the reset link recipient.',
                                ),
                                const SizedBox(height: 18),
                                const _ResetFieldLabel('New password'),
                                const SizedBox(height: 8),
                                _ResetTextField(
                                  controller: _passwordController,
                                  hintText: 'Enter new password',
                                  prefixIcon: Icons.lock_reset_outlined,
                                  obscureText: _obscurePassword,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.next,
                                  validator: _validatePassword,
                                  helperText: isLoading
                                      ? 'Please wait while the request completes.'
                                      : 'Choose a strong password that meets all password rules.',
                                  suffix: IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _ResetFieldLabel('Confirm new password'),
                                const SizedBox(height: 8),
                                _ResetTextField(
                                  controller: _confirmPasswordController,
                                  hintText: 'Confirm new password',
                                  prefixIcon: Icons.verified_user_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  validator: _validateConfirmPassword,
                                  suffix: IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppThemeMetrics.radiusMd + 2,
                                        ),
                                      ),
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            'Reset password',
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetFieldLabel extends StatelessWidget {
  const _ResetFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      text,
      style: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
  }
}

class _ResetTextField extends StatelessWidget {
  const _ResetTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.helperText,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
      borderSide: BorderSide(color: colors.borderSoft),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.inputFill,
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
        ),
        helperText: helperText,
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: colors.textSecondary,
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}