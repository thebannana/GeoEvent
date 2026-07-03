import 'package:flutter/material.dart';

class ReportTextField extends StatelessWidget {
  static const int _minLines = 4;
  static const int _maxLines = 6;
  static const int _maxLength = 2000;
  static const String _hintText = 'Add extra details (optional)';

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ReportTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: _minLines,
      maxLines: _maxLines,
      maxLength: _maxLength,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: _hintText,
        filled: true,
        fillColor: colorScheme.surface,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.75),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.75),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.primary,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}