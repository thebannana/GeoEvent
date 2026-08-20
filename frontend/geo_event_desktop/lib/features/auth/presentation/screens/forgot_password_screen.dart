import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  static const _loggerTag = 'ForgotPasswordScreen';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  @override
  void initState() {
    super.initState();

    AppLogger.debug(
      'Forgot-password screen initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Forgot-password screen disposed.',
      tag: _loggerTag,
    );

    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    return Validators.email(value);
  }

  Future<void> _submit() async {
    final authState = ref.read(authStateProvider);
    final isLoading = authState.isLoading;

    if (isLoading) {
      AppLogger.debug(
        'Duplicate forgot-password request ignored.',
        tag: _loggerTag,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;

    if (form == null) {
      AppLogger.warning(
        'Forgot-password form state was unavailable.',
        tag: _loggerTag,
      );
      return;
    }

    if (!form.validate()) {
      AppLogger.debug(
        'Forgot-password form validation failed.',
        tag: _loggerTag,
      );
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _emailSent = false;
    });

    AppLogger.info(
      'Forgot-password request started.',
      tag: _loggerTag,
    );

    try {
      await ref
          .read(authStateProvider.notifier)
          .forgotPassword(email);

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      AppLogger.info(
        'Forgot-password request completed successfully.',
        tag: _loggerTag,
      );

      _showMessage(
        'If an account exists for this email, a reset link has been sent. '
        'Check your inbox and spam folder.',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Forgot-password request failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _emailSent = false;
      });

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage:
              'Failed to send the reset link. Please try again.',
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
      'User returned to the login screen.',
      tag: _loggerTag,
    );

    context.go('/login');
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
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 540,
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
                      'Forgot Password',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the administrator email address and a reset link will be sent if an account exists.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (_emailSent) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.success.withValues(
                              alpha: 0.32,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mark_email_read_rounded,
                              color: colors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Check your inbox and spam folder for reset instructions.',
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
                    const SizedBox(height: 28),
                    const _ForgotFieldLabel(
                      'Email address',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      onChanged: (_) {
                        if (_emailSent) {
                          setState(() {
                            _emailSent = false;
                          });
                        }
                      },
                      onFieldSubmitted: (_) => _submit(),
                      validator: _validateEmail,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.inputFill,
                        hintText: 'Enter your admin email',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        helperText: isLoading
                            ? 'Sending reset instructions...'
                            : 'Enter the email address linked to your admin account.',
                        helperStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          color: colors.textSecondary,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        border: _inputBorder(colors),
                        enabledBorder: _inputBorder(colors),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppThemeMetrics.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppThemeMetrics.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppThemeMetrics.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
                                'Send reset link',
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
    );
  }

  OutlineInputBorder _inputBorder(AppThemeColors colors) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppThemeMetrics.radiusMd,
      ),
      borderSide: BorderSide(
        color: colors.borderSoft,
      ),
    );
  }
}

class _ForgotFieldLabel extends StatelessWidget {
  const _ForgotFieldLabel(this.text);

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