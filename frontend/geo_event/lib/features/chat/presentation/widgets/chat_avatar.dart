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
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  imageUrl!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _AvatarInitials(
                    title: title,
                    size: size,
                    color: baseColor,
                  ),
                )
              : _AvatarInitials(
                  title: title,
                  size: size,
                  color: baseColor,
                ),
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
    if (cleaned.isEmpty) return '?';

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final token = parts.first;
    if (token.length >= 2) {
      return token.substring(0, 2).toUpperCase();
    }

    return token.substring(0, 1).toUpperCase();
  }
}

class _AvatarInitials extends StatelessWidget {
  final String title;
  final double size;
  final Color color;

  const _AvatarInitials({
    required this.title,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        ChatAvatar._initials(title),
        style: TextStyle(
          fontSize: size * 0.24,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}