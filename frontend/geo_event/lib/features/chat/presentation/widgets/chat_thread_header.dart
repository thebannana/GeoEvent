import 'package:flutter/material.dart';

import '../../../../shared/chat/models/chat_thread_details.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import 'chat_avatar.dart';

class ChatThreadHeader extends StatelessWidget {
  final ChatThreadDetails details;

  const ChatThreadHeader({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveType = _effectiveType(details);
    final isDirect = effectiveType == ChatThreadType.direct;

    final title = _buildTitle(details, effectiveType);
    final subtitle = _buildSubtitle(details, effectiveType);
    final imageUrl = _buildImageUrl(details, effectiveType);
    final avatarSeed = _buildAvatarSeed(details, effectiveType);

    return Row(
      children: [
        ChatAvatar(
          title: avatarSeed,
          imageUrl: imageUrl,
          size: 38,
          type: effectiveType,
          showPresence: isDirect,
          isOnline: isDirect ? details.otherUserIsOnline : false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static ChatThreadType _effectiveType(ChatThreadDetails details) {
    if (details.eventInfo != null) return ChatThreadType.eventGroup;
    if (details.type == ChatThreadType.eventGroup) {
      return ChatThreadType.eventGroup;
    }
    if (details.participants.length > 2) return ChatThreadType.eventGroup;
    return ChatThreadType.direct;
  }

  static String _buildTitle(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      final eventTitle = details.eventInfo?.title.trim();
      if (eventTitle != null && eventTitle.isNotEmpty) {
        return eventTitle;
      }

      final threadTitle = details.title.trim();
      if (threadTitle.isNotEmpty &&
          threadTitle.toLowerCase() != 'direct chat') {
        return threadTitle;
      }

      return 'Event group';
    }

    final displayName = details.otherUserDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final username = _cleanUsername(details.otherUserUsername);
    if (username != null) {
      return username;
    }

    final threadTitle = details.title.trim();
    if (threadTitle.isNotEmpty) {
      return threadTitle;
    }

    return 'Chat';
  }

  static String? _buildSubtitle(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      final count = details.participants.length;
      return count == 1 ? '1 attendee' : '$count attendees';
    }

    if (details.otherUserIsOnline) return 'Online';

    final lastActive = details.otherUserLastActiveAt;
    if (lastActive == null) return null;

    final diff = DateTime.now().difference(lastActive.toLocal());
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }

  static String? _buildImageUrl(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
  ) {
    if (effectiveType == ChatThreadType.direct) {
      final directAvatar = details.otherUserAvatarUrl?.trim();
      if (directAvatar != null && directAvatar.isNotEmpty) {
        return directAvatar;
      }
    }

    final threadImage = details.imageUrl?.trim();
    if (threadImage != null && threadImage.isNotEmpty) {
      return threadImage;
    }

    final eventImage = details.eventInfo?.imageUrl?.trim();
    if (eventImage != null && eventImage.isNotEmpty) {
      return eventImage;
    }

    return null;
  }

  static String _buildAvatarSeed(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      final eventTitle = details.eventInfo?.title.trim();
      if (eventTitle != null && eventTitle.isNotEmpty) {
        return eventTitle;
      }

      final threadTitle = details.title.trim();
      if (threadTitle.isNotEmpty) {
        return threadTitle;
      }

      return 'Group';
    }

    final displayName = details.otherUserDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final username = _cleanUsername(details.otherUserUsername);
    if (username != null) {
      return username;
    }

    final threadTitle = details.title.trim();
    if (threadTitle.isNotEmpty) {
      return threadTitle;
    }

    return 'User';
  }

  static String? _cleanUsername(String? value) {
    final cleaned = (value ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return null;
    return '@$cleaned';
  }
}