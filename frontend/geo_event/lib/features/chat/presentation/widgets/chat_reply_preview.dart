import 'package:flutter/material.dart';

import '../../../../shared/chat/models/message_item.dart';

class ChatReplyPreview extends StatelessWidget {
  final MessageItem message;
  final VoidCallback onClose;

  const ChatReplyPreview({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sender = (message.senderDisplayName?.trim().isNotEmpty ?? false)
        ? message.senderDisplayName!.trim()
        : (message.replySenderName?.trim().isNotEmpty ?? false)
            ? message.replySenderName!.trim()
            : 'Replying';

    final previewText = message.content.trim().isNotEmpty
        ? message.content.trim()
        : 'Message preview unavailable.';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Cancel reply',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}