import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../shell/application/profile_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const _loggerTag = 'ChangePasswordScreen';

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    AppLogger.debug(
      'Change-password screen initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Change-password screen disposed.',
      tag: _loggerTag,
    );

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _onSavePressed() async {
    AppLogger.debug(
      'Save-password action started.',
      tag: _loggerTag,
    );

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;

    if (form == null) {
      AppLogger.warning(
        'Password form state was unavailable.',
        tag: _loggerTag,
      );
      return;
    }

    if (_isSubmitting) {
      AppLogger.debug(
        'Duplicate password-submit action ignored.',
        tag: _loggerTag,
      );
      return;
    }

    if (!form.validate()) {
      AppLogger.debug(
        'Password form validation failed.',
        tag: _loggerTag,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    AppLogger.info(
      'Password-change request started.',
      tag: _loggerTag,
    );

    try {
      await ref.read(profileControllerProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      AppLogger.info(
        'Password-change request completed successfully.',
        tag: _loggerTag,
      );

      if (!mounted) return;

      _showMessage('Password updated successfully.');
      context.pop(true);
    } catch (error, stackTrace) {
  final failureMessage = ErrorMapper.toMessage(
    error,
    stackTrace: stackTrace,
    fallbackMessage: 'Failed to change password.',
  );

      AppLogger.error(
        'Password-change request failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(failureMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      AppLogger.debug(
        'Password-submit state reset.',
        tag: _loggerTag,
      );
    }
  }

  String? _validateCurrentPassword(String? value) {
    return Validators.requiredField(
      value,
      fieldName: 'Current password',
    );
  }

  String? _validateNewPassword(String? value) {
    final currentPassword = _currentPasswordController.text;
    final newPassword = value ?? '';

    final validationMessage = Validators.password(newPassword);

    if (validationMessage != null) {
      return validationMessage;
    }

    if (newPassword == currentPassword) {
      return 'New password must be different from the current password.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.confirmPassword(
      value,
      _newPasswordController.text,
    );
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

  void _toggleCurrentPasswordVisibility() {
    if (_isSubmitting) return;

    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });

    AppLogger.debug(
      'Current-password visibility toggled.',
      tag: _loggerTag,
    );
  }

  void _toggleNewPasswordVisibility() {
    if (_isSubmitting) return;

    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });

    AppLogger.debug(
      'New-password visibility toggled.',
      tag: _loggerTag,
    );
  }

  void _toggleConfirmPasswordVisibility() {
    if (_isSubmitting) return;

    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });

    AppLogger.debug(
      'Confirm-password visibility toggled.',
      tag: _loggerTag,
    );
  }

  void _goBack() {
    if (_isSubmitting) return;

    AppLogger.debug(
      'User left the change-password screen.',
      tag: _loggerTag,
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _goBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                      label: const Text(
                        AppStrings.back,
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
                      'Change Password',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Update the administrator account password for the GeoEvent desktop workspace.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _ChangePasswordFieldLabel(
                      'Current password',
                    ),
                    const SizedBox(height: 8),
                    _ChangePasswordTextField(
                      controller: _currentPasswordController,
                      hintText: 'Enter current password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureCurrentPassword,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: _validateCurrentPassword,
                      suffix: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : _toggleCurrentPasswordVisibility,
                        tooltip: _obscureCurrentPassword
                            ? 'Show current password'
                            : 'Hide current password',
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _ChangePasswordFieldLabel(
                      'New password',
                    ),
                    const SizedBox(height: 8),
                    _ChangePasswordTextField(
                      controller: _newPasswordController,
                      hintText: 'Enter new password',
                      prefixIcon: Icons.lock_reset_outlined,
                      obscureText: _obscureNewPassword,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: _validateNewPassword,
                      suffix: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : _toggleNewPasswordVisibility,
                        tooltip: _obscureNewPassword
                            ? 'Show new password'
                            : 'Hide new password',
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _ChangePasswordFieldLabel(
                      'Confirm new password',
                    ),
                    const SizedBox(height: 8),
                    _ChangePasswordTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm new password',
                      prefixIcon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSavePressed(),
                      validator: _validateConfirmPassword,
                      suffix: IconButton(
                        onPressed: _isSubmitting
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.borderSoft,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Use a strong password with at least 8 characters, including uppercase, lowercase, a number, and a special character.',
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                height: 1.5,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : _goBack,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                                side: BorderSide(
                                  color: colors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppThemeMetrics.radiusMd + 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                AppStrings.cancel,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _onSavePressed,
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
                              child: _isSubmitting
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
                                      'Save password',
                                      style:
                                          textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordFieldLabel extends StatelessWidget {
  const _ChangePasswordFieldLabel(this.text);

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

class _ChangePasswordTextField extends StatelessWidget {
  const _ChangePasswordTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

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