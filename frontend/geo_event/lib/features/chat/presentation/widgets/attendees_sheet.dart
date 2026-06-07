import 'package:flutter/material.dart';
import '../../../../shared/chat/models/chat_participant.dart';

class AttendeesSheet extends StatelessWidget {
  final List<ChatParticipant> participants;

  const AttendeesSheet({
    super.key,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: participants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = participants[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage:
                  item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
              child: item.avatarUrl == null
                  ? Text(
                      item.displayName.isNotEmpty
                          ? item.displayName.characters.first.toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            title: Text(item.displayName),
            subtitle: Text(
              item.joinedAt != null
                  ? 'Joined ${_format(item.joinedAt!)}'
                  : 'Attendee',
            ),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: item.isOnline ? Colors.green : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  static String _format(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}