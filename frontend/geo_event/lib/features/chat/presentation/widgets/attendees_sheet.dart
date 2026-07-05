import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
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

    if (participants.isEmpty) {
      return const AppBottomSheetContainer(
        child: AppEmptyState(
          title: 'No attendees yet',
          message: 'Attendees will appear here once they join.',
          icon: Icons.group_outlined,
        ),
      );
    }

    return AppBottomSheetContainer(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: participants.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = participants[index];
          final username = _cleanUsername(item.username);
          final displayName = _displayName(item.displayName, username);

          final subtitleParts = <String>[
            ?username,
            if (item.joinedAt != null)
              'Joined ${item.joinedAt!.formatDate(pattern: 'dd.MM')}',
          ];

          final subtitle =
              subtitleParts.isEmpty ? 'Attendee' : subtitleParts.join(' • ');

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ChatAvatar(
              title: displayName,
              imageUrl: item.avatarUrl,
              size: 40,
              type: ChatThreadType.direct,
              showPresence: true,
              isOnline: item.isOnline,
            ),
            title: Text(displayName),
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

  static String _displayName(String? displayName, String? username) {
    final cleanedDisplayName = displayName?.trim();
    if (cleanedDisplayName != null && cleanedDisplayName.isNotEmpty) {
      return cleanedDisplayName;
    }
    if (username != null) {
      return username;
    }
    return 'Attendee';
  }

  static String? _cleanUsername(String? value) {
    final cleaned = (value ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return null;
    return '@$cleaned';
  }
}