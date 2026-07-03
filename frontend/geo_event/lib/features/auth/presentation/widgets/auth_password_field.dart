import 'package:flutter/material.dart';

import 'auth_text_field.dart';

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: labelText,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autocorrect: false,
      enableSuggestions: false,
      suffixIcon: IconButton(
        onPressed: enabled ? onToggleVisibility : null,
        tooltip: obscureText ? 'Show password' : 'Hide password',
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
        ),
      ),
    );
  }
}