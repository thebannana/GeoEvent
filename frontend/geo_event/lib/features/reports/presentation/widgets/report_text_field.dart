import 'package:flutter/material.dart';

class ReportTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ReportTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: 4,
      maxLines: 6,
      maxLength: 2000,
      decoration: InputDecoration(
        hintText: 'Add extra details (optional)',
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1F24) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D323A) : const Color(0xFFE6EBF2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D323A) : const Color(0xFFE6EBF2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}