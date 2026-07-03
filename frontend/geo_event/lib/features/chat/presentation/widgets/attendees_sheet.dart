import 'package:flutter/material.dart';

import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import 'chat_avatar.dart';

class AttendeesSheet extends StatelessWidget {
  final List<ChatParticipant> participants;

  const AttendeesSheet({
    super.key,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: participants.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = participants[index];
          final username = _cleanUsername(item.username);

          final subtitleParts = <String>[
            ?username,
            if (item.joinedAt != null) 'Joined ${_format(item.joinedAt!)}',
          ];

          final subtitle =
              subtitleParts.isEmpty ? 'Attendee' : subtitleParts.join(' • ');

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ChatAvatar(
              title: item.displayName,
              imageUrl: item.avatarUrl,
              size: 40,
              type: ChatThreadType.direct,
              showPresence: true,
              isOnline: item.isOnline,
            ),
            title: Text(item.displayName.trim().isNotEmpty
                ? item.displayName.trim()
                : (username ?? 'User ${item.userId}')),
            subtitle: Text(subtitle),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: item.isOnline
                  ? colorScheme.primary
                  : colorScheme.outline,
            ),
          );
        },
      ),
    );
  }

  static String? _cleanUsername(String? value) {
    final cleaned = (value ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return null;
    return '@$cleaned';
  }

  static String _format(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }
}