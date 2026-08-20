import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
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

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  static const _loggerTag = 'ResetPasswordScreen';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetCompleted = false;

  String get _hiddenToken {
    return widget.initialToken?.trim() ?? '';
  }

  bool get _hasValidResetPayload {
    return _hiddenToken.isNotEmpty &&
        _emailController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.initialEmail?.trim() ?? '';

    AppLogger.debug(
      'Reset-password screen initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Reset-password screen disposed.',
      tag: _loggerTag,
    );

    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  String? _validateEmail(String? value) {
    return Validators.email(value);
  }

  String? _validatePassword(String? value) {
    return Validators.password(value);
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.confirmPassword(
      value,
      _passwordController.text,
    );
  }

  Future<void> _submit() async {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      AppLogger.debug(
        'Duplicate password-reset request ignored.',
        tag: _loggerTag,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_hasValidResetPayload) {
      AppLogger.warning(
        'Password-reset request rejected because the reset payload was incomplete.',
        tag: _loggerTag,
      );

      _showMessage(
        'This password reset link is invalid or incomplete. '
        'Request a new reset email and try again.',
      );
      return;
    }

    final form = _formKey.currentState;

    if (form == null) {
      AppLogger.warning(
        'Reset-password form state was unavailable.',
        tag: _loggerTag,
      );
      return;
    }

    if (!form.validate()) {
      AppLogger.debug(
        'Reset-password form validation failed.',
        tag: _loggerTag,
      );
      return;
    }

    AppLogger.info(
      'Password-reset request started.',
      tag: _loggerTag,
    );

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

      AppLogger.info(
        'Password-reset request completed successfully.',
        tag: _loggerTag,
      );

      _showMessage(
        'Your password has been reset successfully.',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Password-reset request failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage:
              'Failed to reset the password. Please request a new reset link and try again.',
        ),
      );
    }
  }

  void _goToLogin() {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      return;
    }

    AppLogger.debug(
      'User returned to the login screen from password reset.',
      tag: _loggerTag,
    );

    context.go('/login');
  }

  void _goToForgotPassword() {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      return;
    }

    AppLogger.debug(
      'User requested a new password-reset link.',
      tag: _loggerTag,
    );

    context.go('/forgot-password');
  }

  void _togglePasswordVisibility() {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      return;
    }

    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      return;
    }

    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.border,
                ),
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
                  ? _buildCompletedContent(context)
                  : !_hasValidResetPayload
                      ? _buildInvalidPayloadContent(context)
                      : _buildResetForm(
                          context,
                          isLoading: isLoading,
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
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
        _MessagePanel(
          backgroundColor: colors.success.withValues(
            alpha: 0.14,
          ),
          borderColor: colors.success.withValues(
            alpha: 0.32,
          ),
          icon: Icons.check_circle_outline_rounded,
          iconColor: colors.success,
          text:
              'The reset link has been used successfully. For security, use the latest email if you ever need to reset the password again.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToLogin,
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
    );
  }

  Widget _buildInvalidPayloadContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _goToForgotPassword,
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          label: const Text(
            'Back to forgot password',
          ),
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
        _MessagePanel(
          backgroundColor: colors.warning.withValues(
            alpha: 0.14,
          ),
          borderColor: colors.warning.withValues(
            alpha: 0.34,
          ),
          icon: Icons.info_outline_rounded,
          iconColor: colors.warning,
          text:
              'Go back to the forgot password screen, request a new email, and open the latest reset link.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToForgotPassword,
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
              'Request a new reset link',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(
    BuildContext context, {
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AbsorbPointer(
      absorbing: isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: isLoading ? null : _goToLogin,
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: const Text(
                'Back to login',
              ),
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
            const _ResetFieldLabel(
              'Email address',
            ),
            const SizedBox(height: 8),
            _ResetTextField(
              controller: _emailController,
              hintText: 'Enter your admin email',
              prefixIcon: Icons.alternate_email_rounded,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              helperText: 'This email should match the reset link recipient.',
            ),
            const SizedBox(height: 18),
            const _ResetFieldLabel(
              'New password',
            ),
            const SizedBox(height: 8),
            _ResetTextField(
              controller: _passwordController,
              hintText: 'Enter new password',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscurePassword,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
              helperText:
                  'Use at least 8 characters with uppercase, lowercase, a number, and a special character.',
              suffix: IconButton(
                onPressed:
                    isLoading ? null : _togglePasswordVisibility,
                tooltip: _obscurePassword
                    ? 'Show new password'
                    : 'Hide new password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ResetFieldLabel(
              'Confirm new password',
            ),
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
                    : _toggleConfirmPasswordVisibility,
                tooltip: _obscureConfirmPassword
                    ? 'Show confirmation password'
                    : 'Hide confirmation password',
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
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
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

class _ResetFieldLabel extends StatelessWidget {
  const _ResetFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
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
      borderRadius: BorderRadius.circular(
        AppThemeMetrics.radiusMd,
      ),
      borderSide: BorderSide(
        color: colors.borderSoft,
      ),
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
          color: colors.textSecondary.withValues(
            alpha: 0.72,
          ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppThemeMetrics.radiusMd,
          ),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppThemeMetrics.radiusMd,
          ),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppThemeMetrics.radiusMd,
          ),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}