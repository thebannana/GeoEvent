import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _loggerTag = 'LoginScreen';

  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();

    AppLogger.debug(
      'Login screen initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Login screen disposed.',
      tag: _loggerTag,
    );

    _emailOrUsernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final currentAuthState = ref.read(authStateProvider);

    if (currentAuthState.isLoading) {
      AppLogger.debug(
        'Duplicate login request ignored.',
        tag: _loggerTag,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;

    if (form == null) {
      AppLogger.warning(
        'Login form state was unavailable.',
        tag: _loggerTag,
      );
      return;
    }

    if (!form.validate()) {
      AppLogger.debug(
        'Login form validation failed.',
        tag: _loggerTag,
      );
      return;
    }

    AppLogger.info(
      'Login request started.',
      tag: _loggerTag,
    );

    try {
      await ref.read(authStateProvider.notifier).login(
            emailOrUsername: _emailOrUsernameController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

      if (!mounted) return;

      AppLogger.info(
        'Login request completed successfully.',
        tag: _loggerTag,
      );

      context.go('/admin');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Login request failed.',
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
              'Login failed. Please check your credentials and try again.',
        ),
      );
    }
  }

  void _togglePasswordVisibility() {
    final currentAuthState = ref.read(authStateProvider);

    if (currentAuthState.isLoading) {
      return;
    }

    setState(() {
      _obscurePassword = !_obscurePassword;
    });

    AppLogger.debug(
      'Password visibility toggled.',
      tag: _loggerTag,
    );
  }

  void _setRememberMe(bool? value) {
    final currentAuthState = ref.read(authStateProvider);

    if (currentAuthState.isLoading) {
      return;
    }

    setState(() {
      _rememberMe = value ?? false;
    });

    AppLogger.debug(
      'Remember-me preference changed.',
      tag: _loggerTag,
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;

          if (isCompact) {
            return _CompactLoginLayout(
              formKey: _formKey,
              emailOrUsernameController:
                  _emailOrUsernameController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              rememberMe: _rememberMe,
              isLoading: isLoading,
              onTogglePassword: _togglePasswordVisibility,
              onRememberMeChanged: _setRememberMe,
              onLoginPressed:
                  isLoading ? null : _onLoginPressed,
              onForgotPassword: isLoading
                  ? null
                  : () => context.go('/forgot-password'),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 6,
                child: _CompactLoginLayout(
                  formKey: _formKey,
                  emailOrUsernameController:
                      _emailOrUsernameController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  rememberMe: _rememberMe,
                  isLoading: isLoading,
                  onTogglePassword: _togglePasswordVisibility,
                  onRememberMeChanged: _setRememberMe,
                  onLoginPressed:
                      isLoading ? null : _onLoginPressed,
                  onForgotPassword: isLoading
                      ? null
                      : () => context.go('/forgot-password'),
                ),
              ),
              Expanded(
                flex: 5,
                child: _LoginInformationPanel(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompactLoginLayout extends StatelessWidget {
  const _CompactLoginLayout({
    required this.formKey,
    required this.emailOrUsernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onLoginPressed,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailOrUsernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      color: colors.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AuthBackgroundPainter(
                dotColor: colors.borderSoft,
                waveColor: colors.border,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                child: _LoginCard(
                  formKey: formKey,
                  emailOrUsernameController:
                      emailOrUsernameController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  rememberMe: rememberMe,
                  isLoading: isLoading,
                  onTogglePassword: onTogglePassword,
                  onRememberMeChanged: onRememberMeChanged,
                  onLoginPressed: onLoginPressed,
                  onForgotPassword: onForgotPassword,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginInformationPanel extends StatelessWidget {
  const _LoginInformationPanel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF183244),
                  Color(0xFF2C82A6),
                ]
              : const [
                  Color(0xFF8AC6E4),
                  Color(0xFF5FAAD0),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Desktop control for the entire GeoEvent platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Manage users, events, categories, reports, and platform activity from one administrative workspace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailOrUsernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onLoginPressed,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailOrUsernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.96),
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
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/geoevent.png',
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            Text(
              'Admin Login',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access the GeoEvent desktop administration panel.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            const _FieldLabel(
              'Email or username',
            ),
            const SizedBox(height: 8),
            _LoginTextField(
              controller: emailOrUsernameController,
              hintText: 'Enter your email or username',
              prefixIcon: Icons.person_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final requiredMessage =
                    Validators.requiredField(
                  value,
                  fieldName: 'Email or username',
                );

                if (requiredMessage != null) {
                  return requiredMessage;
                }

                if (value!.trim().length < 3) {
                  return 'Email or username must be at least 3 characters.';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel(
              'Password',
            ),
            const SizedBox(height: 8),
            _LoginTextField(
              controller: passwordController,
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLoginPressed?.call(),
              validator: (value) {
                return Validators.requiredField(
                  value,
                  fieldName: 'Password',
                );
              },
              suffix: IconButton(
                onPressed:
                    isLoading ? null : onTogglePassword,
                tooltip: obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  activeColor: colorScheme.primary,
                  onChanged: isLoading
                      ? null
                      : onRememberMeChanged,
                ),
                Text(
                  'Remember me',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onForgotPassword,
                  child: Text(
                    'Forgot password?',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onLoginPressed,
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
                        'Sign in',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.go('/privacy'),
                child: Text(
                  'Privacy policy',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
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
            alpha: 0.7,
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

class _AuthBackgroundPainter extends CustomPainter {
  const _AuthBackgroundPainter({
    required this.dotColor,
    required this.waveColor,
  });

  final Color dotColor;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 18.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          1.1,
          dotPaint,
        );
      }
    }

    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final firstPath = Path()
      ..moveTo(0, size.height - 120)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height - 30,
        size.width * 0.5,
        size.height - 90,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height - 150,
        size.width,
        size.height - 60,
      );

    final secondPath = Path()
      ..moveTo(0, size.height - 90)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height,
        size.width * 0.5,
        size.height - 55,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height - 110,
        size.width,
        size.height - 20,
      );

    canvas
      ..drawPath(firstPath, wavePaint)
      ..drawPath(secondPath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.waveColor != waveColor;
  }
}