import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_details.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../widgets/chat_avatar.dart';

class ChatDetailsScreen extends StatelessWidget {
  final ChatThreadDetails details;
  final Future<void> Function()? onLeaveGroup;
  final void Function(ChatParticipant participant)? onOpenParticipant;
  final VoidCallback? onOpenEventDetails;
  final int? currentUserId;

  const ChatDetailsScreen({
    super.key,
    required this.details,
    this.onLeaveGroup,
    this.onOpenParticipant,
    this.onOpenEventDetails,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveType = _effectiveType(details);
    final isDirect = effectiveType == ChatThreadType.direct;
    final otherParticipant = _resolveOtherParticipant(details, currentUserId);

    final heroTitle = _heroTitle(details, effectiveType, otherParticipant);
    final heroSubtitle = _heroSubtitle(details, effectiveType, otherParticipant);
    final heroImage = _heroImage(details, effectiveType, otherParticipant);
    final avatarSeed = _avatarSeed(details, effectiveType, otherParticipant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            child: Column(
              children: [
                ChatAvatar(
                  title: avatarSeed,
                  imageUrl: heroImage,
                  size: 72,
                  type: effectiveType,
                  showPresence: isDirect,
                  isOnline: isDirect
                      ? (otherParticipant?.isOnline ?? details.otherUserIsOnline)
                      : false,
                ),
                const SizedBox(height: 12),
                Text(
                  heroTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (heroSubtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    heroSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (details.eventInfo != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Event'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((details.eventInfo!.imageUrl ?? '').trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            details.eventInfo!.imageUrl!.trim(),
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return _EventImageFallback(
                                title: details.eventInfo!.title,
                              );
                            },
                          ),
                        )
                      else
                        _EventImageFallback(
                          title: details.eventInfo!.title,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details.eventInfo!.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((details.eventInfo!.venueName ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                details.eventInfo!.venueName!.trim(),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.78),
                                ),
                              ),
                            ],
                            if ((details.eventInfo!.cityName ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                details.eventInfo!.cityName!.trim(),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.78),
                                ),
                              ),
                            ],
                            if (details.eventInfo!.startsAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _formatEventStart(details.eventInfo!.startsAt!),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (onOpenEventDetails != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onOpenEventDetails,
                        icon: const Icon(Icons.event_outlined),
                        label: const Text('View event details'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(isDirect ? 'Person' : 'Attendees'),
                const SizedBox(height: 12),
                if (details.participants.isEmpty)
                  Text(
                    'No participants available.',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < details.participants.length; i++) ...[
                        _ParticipantTile(
                          participant: details.participants[i],
                          onTap: onOpenParticipant == null
                              ? null
                              : () => onOpenParticipant!(details.participants[i]),
                        ),
                        if (i != details.participants.length - 1)
                          Divider(
                            height: 18,
                            color: isDark
                                ? const Color(0xFF2A303A)
                                : const Color(0xFFE5EAF2),
                          ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (!isDirect) ...[
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Group access'),
                  const SizedBox(height: 10),
                  Text(
                    'If you leave this event chat, you will lose access and won’t be able to rejoin it manually later.',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This group is also automatically removed when the event finishes.',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.82),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onLeaveGroup == null
                          ? null
                          : () => _confirmLeaveGroup(context),
                      icon: const Icon(Icons.exit_to_app_rounded),
                      label: const Text('Leave group'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLeaveGroup(BuildContext context) async {
    final action = onLeaveGroup;
    if (action == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text(
          'You will lose access to this event chat and won’t be able to rejoin it manually later. This group is automatically removed when the event finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave group'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await action();
    if (context.mounted) Navigator.of(context).pop();
  }

  static ChatThreadType _effectiveType(ChatThreadDetails details) {
    if (details.eventInfo != null) return ChatThreadType.eventGroup;
    if (details.participants.length > 2) return ChatThreadType.eventGroup;
    if (details.type == ChatThreadType.eventGroup) return ChatThreadType.eventGroup;
    return ChatThreadType.direct;
  }

  static ChatParticipant? _resolveOtherParticipant(
    ChatThreadDetails details,
    int? currentUserId,
  ) {
    if (details.participants.isEmpty) return null;

    if (details.otherUserId != null) {
      for (final participant in details.participants) {
        if (participant.userId == details.otherUserId) return participant;
      }
    }

    if (currentUserId != null) {
      for (final participant in details.participants) {
        if (participant.userId != currentUserId) return participant;
      }
    }

    return details.participants.first;
  }

  static String _heroTitle(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
    ChatParticipant? otherParticipant,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      if (details.eventInfo?.title.trim().isNotEmpty == true) {
        return details.eventInfo!.title.trim();
      }

      final title = details.title.trim();
      if (title.isNotEmpty && title.toLowerCase() != 'direct chat') {
        return title;
      }

      return 'Event group';
    }

    final directName = (details.otherUserDisplayName ?? '').trim();
    if (directName.isNotEmpty) return directName;

    final directUsername = _cleanUsername(details.otherUserUsername);
    if (directUsername != null) return '@$directUsername';

    if (otherParticipant != null) {
      final displayName = otherParticipant.displayName.trim();
      if (displayName.isNotEmpty) return displayName;

      final username = _cleanUsername(otherParticipant.username);
      if (username != null) return '@$username';
    }

    return 'Direct chat';
  }

  static String? _heroSubtitle(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
    ChatParticipant? otherParticipant,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      final count = details.participants.length;
      return count == 1 ? '1 attendee' : '$count attendees';
    }

    final directUsername = _cleanUsername(details.otherUserUsername);
    if (directUsername != null) return '@$directUsername';

    if (details.otherUserIsOnline) return 'Online';

    final directLastActive = details.otherUserLastActiveAt;
    if (directLastActive != null) {
      return 'Active ${_relativeTime(directLastActive)}';
    }

    if (otherParticipant != null) {
      if (otherParticipant.isOnline) return 'Online';
      if (otherParticipant.lastActiveAt != null) {
        return 'Active ${_relativeTime(otherParticipant.lastActiveAt!)}';
      }
    }

    return null;
  }

  static String? _heroImage(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
    ChatParticipant? otherParticipant,
  ) {
    if (effectiveType == ChatThreadType.direct) {
      final directAvatar = details.otherUserAvatarUrl?.trim();
      if (directAvatar != null && directAvatar.isNotEmpty) return directAvatar;

      final participantAvatar = otherParticipant?.avatarUrl?.trim();
      if (participantAvatar != null && participantAvatar.isNotEmpty) {
        return participantAvatar;
      }
    }

    final image = details.imageUrl?.trim();
    if (image != null && image.isNotEmpty) return image;

    final eventImage = details.eventInfo?.imageUrl?.trim();
    if (eventImage != null && eventImage.isNotEmpty) return eventImage;

    return null;
  }

  static String _avatarSeed(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
    ChatParticipant? otherParticipant,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      if (details.eventInfo?.title.trim().isNotEmpty == true) {
        return details.eventInfo!.title.trim();
      }

      final title = details.title.trim();
      if (title.isNotEmpty && title.toLowerCase() != 'direct chat') {
        return title;
      }

      return 'Group';
    }

    final directName = (details.otherUserDisplayName ?? '').trim();
    if (directName.isNotEmpty) return directName;

    final directUsername = _cleanUsername(details.otherUserUsername);
    if (directUsername != null) return directUsername;

    if (otherParticipant != null) {
      final displayName = otherParticipant.displayName.trim();
      if (displayName.isNotEmpty) return displayName;

      final username = _cleanUsername(otherParticipant.username);
      if (username != null) return username;
    }

    return 'User';
  }

  static String? _cleanUsername(String? value) {
    final cleaned = (value ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  static String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String _formatEventStart(DateTime value) {
    final local = value.toLocal();
    return 'Starts ${DateFormat('EEE, d MMM • HH:mm').format(local)}';
  }
}

class _ParticipantTile extends StatelessWidget {
  final ChatParticipant participant;
  final VoidCallback? onTap;

  const _ParticipantTile({
    required this.participant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = _participantTitle(participant);
    final subtitle = _participantSubtitle(participant);
    final avatarSeed = _participantAvatarSeed(participant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ChatAvatar(
                title: avatarSeed,
                imageUrl: participant.avatarUrl,
                size: 44,
                type: ChatThreadType.direct,
                showPresence: true,
                isOnline: participant.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static String _participantTitle(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    if (displayName.isNotEmpty) return displayName;

    final username = _cleanUsername(participant.username);
    if (username != null) return '@$username';

    return 'User ${participant.userId}';
  }

  static String? _participantSubtitle(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    final username = _cleanUsername(participant.username);

    if (displayName.isNotEmpty && username != null) {
      return '@$username';
    }

    return null;
  }

  static String _participantAvatarSeed(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    if (displayName.isNotEmpty) return displayName;

    final username = _cleanUsername(participant.username);
    if (username != null) return username;

    return 'User';
  }

  static String? _cleanUsername(String? value) {
    final cleaned = (value ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _EventImageFallback extends StatelessWidget {
  final String title;
  const _EventImageFallback({required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(title),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}