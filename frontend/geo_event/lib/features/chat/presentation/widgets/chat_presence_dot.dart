import 'package:flutter/material.dart';

class ChatPresenceDot extends StatelessWidget {
  final bool isOnline;

  const ChatPresenceDot({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }
}