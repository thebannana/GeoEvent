import 'package:flutter/material.dart';

import '../../../../shared/chat/models/chat_thread_type.dart';
import 'chat_presence_dot.dart';

class ChatAvatar extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double size;
  final ChatThreadType? type;
  final bool showPresence;
  final bool isOnline;

  const ChatAvatar({
    super.key,
    required this.title,
    required this.imageUrl,
    this.size = 46,
    this.type,
    this.showPresence = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final baseColor = colorScheme.primary;
    final shouldShowPresence =
        showPresence && type == ChatThreadType.direct;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withValues(alpha: 0.14),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(imageUrl!.trim()),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasImage
              ? Center(
                  child: Text(
                    _initials(title),
                    style: TextStyle(
                      fontSize: size * 0.24,
                      fontWeight: FontWeight.w700,
                      color: baseColor,
                    ),
                  ),
                )
              : null,
        ),
        if (shouldShowPresence)
          Positioned(
            right: -1,
            bottom: -1,
            child: ChatPresenceDot(isOnline: isOnline),
          ),
      ],
    );
  }

  static String _initials(String value) {
    final cleaned = value.trim().replaceFirst(RegExp(r'^@+'), '');
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}