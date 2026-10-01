import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (ref.read(authStateProvider).isLoading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            birthDate: DateTime(2000, 1, 1), // Default birthDate since it's not collected here
            phoneNumber: '+123456789', // Default since it's not collected
            consentGiven: true,
            consentVersion: '1.0',
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

      if (!mounted) return;
      context.go('/admin');
    } catch (error, stackTrace) {
      if (!mounted) return;
      
      final errorMessage = error.toString();
      if (errorMessage.contains('available only to administrators')) {
        _showMessage('Account created successfully. An existing administrator must grant you admin access before you can log in.');
        context.go('/login');
      } else {
        _showMessage(ErrorMapper.toMessage(error, stackTrace: stackTrace, fallbackMessage: 'Registration failed.'));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colors.card.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
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
                                Text(
                                  'Register Admin',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a new administrative account.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RegisterField(
                                        label: 'First name',
                                        controller: _firstNameController,
                                        icon: Icons.person_outline,
                                        enabled: !isLoading,
                                        validator: (v) => Validators.requiredField(v, fieldName: 'First name'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _RegisterField(
                                        label: 'Last name',
                                        controller: _lastNameController,
                                        icon: Icons.person_outline,
                                        enabled: !isLoading,
                                        validator: (v) => Validators.requiredField(v, fieldName: 'Last name'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _RegisterField(
                                  label: 'Username',
                                  controller: _usernameController,
                                  icon: Icons.alternate_email,
                                  enabled: !isLoading,
                                  validator: (v) => Validators.requiredField(v, fieldName: 'Username'),
                                ),
                                const SizedBox(height: 16),
                                _RegisterField(
                                  label: 'Email',
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  enabled: !isLoading,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),
                                _RegisterField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  enabled: !isLoading,
                                  validator: (v) => Validators.requiredField(v, fieldName: 'Password'),
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _RegisterField(
                                  label: 'Confirm Password',
                                  controller: _confirmPasswordController,
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  enabled: !isLoading,
                                  validator: (v) => Validators.requiredField(v, fieldName: 'Confirm Password'),
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onRegisterPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd + 2),
                                      ),
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: TextButton(
                                    onPressed: isLoading ? null : () => context.go('/login'),
                                    child: Text(
                                      'Already have an account? Sign in',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: _RegisterInformationPanel(),
          ),
        ],
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _RegisterField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
      borderSide: BorderSide(color: colors.borderSoft),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            prefixIcon: Icon(icon, color: colors.textSecondary),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterInformationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF183244), Color(0xFF2C82A6)]
              : const [Color(0xFF8AC6E4), Color(0xFF5FAAD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Join GeoEvent',
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
                'Register a new account to access the administrative dashboard and manage events.',
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
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final firstPath = Path()
      ..moveTo(0, size.height - 120)
      ..quadraticBezierTo(size.width * 0.2, size.height - 30, size.width * 0.5, size.height - 90)
      ..quadraticBezierTo(size.width * 0.75, size.height - 150, size.width, size.height - 60);

    final secondPath = Path()
      ..moveTo(0, size.height - 90)
      ..quadraticBezierTo(size.width * 0.2, size.height, size.width * 0.5, size.height - 55)
      ..quadraticBezierTo(size.width * 0.75, size.height - 110, size.width, size.height - 20);

    canvas..drawPath(firstPath, wavePaint)..drawPath(secondPath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) => false;
}
