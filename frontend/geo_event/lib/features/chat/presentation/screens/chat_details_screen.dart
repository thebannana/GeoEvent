import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_details.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../widgets/chat_avatar.dart';

class ChatDetailsScreen extends StatelessWidget {
  final ChatThreadDetails details;
  final Future<void> Function()? onLeaveThread;
  final void Function(ChatParticipant participant)? onOpenParticipant;
  final VoidCallback? onOpenEventDetails;
  final int? currentUserId;

  const ChatDetailsScreen({
    super.key,
    required this.details,
    this.onLeaveThread,
    this.onOpenParticipant,
    this.onOpenEventDetails,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveType = effectiveThreadType(details);
    final isDirect = effectiveType == ChatThreadType.direct;
    final otherParticipant = resolveOtherParticipant(details, currentUserId);
    final resolvedHeroTitle =
        heroTitle(details, effectiveType, otherParticipant);
    final resolvedHeroSubtitle =
        heroSubtitle(details, effectiveType, otherParticipant);
    final resolvedHeroImage =
        heroImage(details, effectiveType, otherParticipant);
    final resolvedAvatarSeed =
        avatarSeed(details, effectiveType, otherParticipant);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Chat details'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                ChatAvatar(
                  title: resolvedAvatarSeed,
                  imageUrl: resolvedHeroImage,
                  size: 72,
                  type: effectiveType,
                  showPresence: isDirect,
                  isOnline: isDirect
                      ? (otherParticipant?.isOnline ?? details.otherUserIsOnline)
                      : false,
                ),
                const SizedBox(height: 12),
                Text(
                  resolvedHeroTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (resolvedHeroSubtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    resolvedHeroSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (details.eventInfo != null) ...[
            const SizedBox(height: 16),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Event'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.eventInfo!.imageUrl?.trim().isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            details.eventInfo!.imageUrl!.trim(),
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return EventImageFallback(
                                title: details.eventInfo!.title,
                              );
                            },
                          ),
                        )
                      else
                        EventImageFallback(title: details.eventInfo!.title),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details.eventInfo!.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (details.eventInfo!.startsAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Starts ${details.eventInfo!.startsAt!.formatEventDateTime()}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
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
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(isDirect ? 'Person' : 'Attendees'),
                const SizedBox(height: 12),
                if (details.participants.isEmpty)
                  const AppEmptyState(
                    title: 'No participants available',
                    message: 'Participant details are not available yet.',
                    icon: Icons.group_outlined,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < details.participants.length; i++) ...[
                        ParticipantTile(
                          participant: details.participants[i],
                          onTap: onOpenParticipant == null
                              ? null
                              : () => onOpenParticipant!(details.participants[i]),
                        ),
                        if (i != details.participants.length - 1)
                          const Divider(height: 18),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(isDirect ? 'Chat access' : 'Group access'),
                const SizedBox(height: 10),
                Text(
                  isDirect
                      ? 'If you remove this direct chat, it will disappear from your inbox. It can appear again later if a direct conversation is opened again.'
                      : 'If you leave this event chat, you will lose access and will not be able to rejoin it manually later.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDirect
                      ? 'This does not delete the conversation for the other person.'
                      : 'This group is also automatically removed when the event finishes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLeaveThread == null
                        ? null
                        : () => confirmLeaveThread(context),
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: Text(isDirect ? 'Remove chat' : 'Leave group'),
                  ),
                ),
                if (onLeaveThread == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'This action is currently unavailable.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> confirmLeaveThread(BuildContext context) async {
    final action = onLeaveThread;
    if (action == null) return;

    final navigator = Navigator.of(context);
    final isDirect = effectiveThreadType(details) == ChatThreadType.direct;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: isDirect ? 'Remove chat?' : 'Leave group?',
      message: isDirect
          ? 'This chat will be removed from your inbox. You can see it again if a direct conversation is opened later.'
          : 'You will lose access to this event chat and will not be able to rejoin it manually later. This group is automatically removed when the event finishes.',
      confirmLabel: isDirect ? 'Remove chat' : 'Leave group',
    );

    if (confirmed != true) return;

    await action();
    navigator.pop();
  }

  static ChatThreadType effectiveThreadType(ChatThreadDetails details) {
    if (details.eventInfo != null) return ChatThreadType.eventGroup;
    if (details.type == ChatThreadType.eventGroup) {
      return ChatThreadType.eventGroup;
    }
    if (details.participants.length > 2) return ChatThreadType.eventGroup;
    return ChatThreadType.direct;
  }

  static ChatParticipant? resolveOtherParticipant(
    ChatThreadDetails details,
    int? currentUserId,
  ) {
    if (details.participants.isEmpty) return null;

    if (details.otherUserId != null) {
      for (final participant in details.participants) {
        if (participant.userId == details.otherUserId) {
          return participant;
        }
      }
    }

    if (currentUserId != null) {
      for (final participant in details.participants) {
        if (participant.userId != currentUserId) {
          return participant;
        }
      }
    }

    return details.participants.first;
  }

  static String heroTitle(
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

    final directName = details.otherUserDisplayName?.trim();
    if (directName != null && directName.isNotEmpty) return directName;

    final directUsername = cleanUsername(details.otherUserUsername);
    if (directUsername != null) return directUsername;

    if (otherParticipant != null) {
      final displayName = otherParticipant.displayName.trim();
      if (displayName.isNotEmpty) return displayName;

      final username = cleanUsername(otherParticipant.username);
      if (username != null) return username;
    }

    return 'Direct chat';
  }

  static String? heroSubtitle(
    ChatThreadDetails details,
    ChatThreadType effectiveType,
    ChatParticipant? otherParticipant,
  ) {
    if (effectiveType == ChatThreadType.eventGroup) {
      final count = details.participants.length;
      return count == 1 ? '1 attendee' : '$count attendees';
    }

    if (details.otherUserIsOnline) return 'Online';

    final directLastActive = details.otherUserLastActiveAt;
    if (directLastActive != null) {
      return 'Active ${directLastActive.timeAgo(short: false)}';
    }

    if (otherParticipant != null) {
      if (otherParticipant.isOnline) return 'Online';
      if (otherParticipant.lastActiveAt != null) {
        return 'Active ${otherParticipant.lastActiveAt!.timeAgo(short: false)}';
      }
    }

    final directUsername = cleanUsername(details.otherUserUsername);
    if (directUsername != null) return directUsername;

    return null;
  }

  static String? heroImage(
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

  static String avatarSeed(
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

    final directName = details.otherUserDisplayName?.trim();
    if (directName != null && directName.isNotEmpty) return directName;

    final directUsername = cleanUsername(details.otherUserUsername);
    if (directUsername != null) return directUsername;

    if (otherParticipant != null) {
      final displayName = otherParticipant.displayName.trim();
      if (displayName.isNotEmpty) return displayName;

      final username = cleanUsername(otherParticipant.username);
      if (username != null) return username;
    }

    return 'User';
  }

  static String? cleanUsername(String? value) {
    final cleaned = value?.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned == null || cleaned.isEmpty) return null;
    return '@$cleaned';
  }
}

class ParticipantTile extends StatelessWidget {
  final ChatParticipant participant;
  final VoidCallback? onTap;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = participantTitle(participant);
    final subtitle = participantSubtitle(participant);
    final avatarSeed = participantAvatarSeed(participant);

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
                      style: theme.textTheme.bodyMedium?.copyWith(
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

  static String participantTitle(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    if (displayName.isNotEmpty) return displayName;

    final username = ChatDetailsScreen.cleanUsername(participant.username);
    if (username != null) return username;

    return 'Participant';
  }

  static String? participantSubtitle(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    final username = ChatDetailsScreen.cleanUsername(participant.username);
    if (displayName.isNotEmpty && username != null) return username;
    return null;
  }

  static String participantAvatarSeed(ChatParticipant participant) {
    final displayName = participant.displayName.trim();
    if (displayName.isNotEmpty) return displayName;

    final username = ChatDetailsScreen.cleanUsername(participant.username);
    if (username != null) return username;

    return 'User';
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class EventImageFallback extends StatelessWidget {
  final String title;

  const EventImageFallback({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials(title),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String initials(String value) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}