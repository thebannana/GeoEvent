import 'package:flutter/material.dart';

class CommentAvatar extends StatelessWidget {
  final double size;
  final String fallbackText;
  final String? avatarUrl;
  final double fontSize;

  const CommentAvatar({
    super.key,
    required this.size,
    required this.fallbackText,
    this.avatarUrl,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(fallbackText);
    final colorScheme = Theme.of(context).colorScheme;
    final cleanedAvatarUrl = avatarUrl?.trim();

    if (cleanedAvatarUrl != null && cleanedAvatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(cleanedAvatarUrl),
        onBackgroundImageError: (_, _) {},
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.85),
            colorScheme.secondary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildInitials(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '?';

    final parts =
        cleaned.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    final first = _firstVisibleChar(parts.first);
    if (parts.length == 1) return first.toUpperCase();

    final second = _firstVisibleChar(parts[1]);
    return '$first$second'.toUpperCase();
  }

  String _firstVisibleChar(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1);
  }
}