import 'package:flutter/material.dart';

import 'auth_text_field.dart';

class AuthDateField extends StatelessWidget {
  const AuthDateField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.validator,
    this.onTap,
    this.enabled = true,
    this.helperText,
  });

  final TextEditingController controller;
  final String labelText;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: labelText,
      readOnly: true,
      onTap: enabled ? onTap : null,
      validator: validator,
      suffixIcon: const Icon(Icons.calendar_today),
      helperText: helperText,
      enabled: enabled,
    );
  }
}