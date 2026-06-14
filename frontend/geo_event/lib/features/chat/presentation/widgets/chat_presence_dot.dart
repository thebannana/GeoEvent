import 'package:flutter/material.dart';

class ChatPresenceDot extends StatelessWidget {
  final bool isOnline;

  const ChatPresenceDot({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? colorScheme.primary : colorScheme.outline,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }
}