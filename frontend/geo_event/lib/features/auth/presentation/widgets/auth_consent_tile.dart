import 'package:flutter/material.dart';

class AuthConsentTile extends StatelessWidget {
  const AuthConsentTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}