import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/models/message_item.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/chat_thread_controller.dart';
import '../../application/messages_controller.dart';
import '../widgets/attendees_sheet.dart';
import '../widgets/chat_reply_preview.dart';
import '../widgets/event_chat_info_card.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final ChatThreadArgs args;

  const ChatThreadScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  bool _eventCardDismissed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;

      final controller =
          ref.read(chatThreadControllerProvider(widget.args).notifier);

      try {
        await controller.connectRealtime();
        if (!mounted) return;

        await controller.markThreadRead();
        if (!mounted) return;

        ref
            .read(messagesInboxControllerProvider.notifier)
            .markThreadLocallyRead(widget.args.threadId);
      } catch (e, st) {
        debugPrint('ChatThreadScreen init error: $e');
        debugPrintStack(stackTrace: st);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadControllerProvider(widget.args));
    final controller =
        ref.read(chatThreadControllerProvider(widget.args).notifier);
    final myUserId = ref.watch(authStateProvider).user?.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: state.details.when(
          data: (details) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (details.type == ChatThreadType.direct &&
                  details.participants.isNotEmpty)
                Text(
                  _presenceLabel(details.participants),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          error: (_, __) => Text(widget.args.title),
          loading: () => Text(widget.args.title),
        ),
        actions: [
          state.details.maybeWhen(
            data: (details) {
              if (details.type != ChatThreadType.eventGroup) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Attendees',
                onPressed: details.participants.isEmpty
                    ? null
                    : () => _showAttendeesSheet(context, details.participants),
                icon: const Icon(Icons.group_outlined),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          state.details.maybeWhen(
            data: (details) {
              final eventInfo = details.eventInfo;
              if (eventInfo == null || _eventCardDismissed) {
                return const SizedBox.shrink();
              }

              return EventChatInfoCard(
                info: eventInfo,
                onClose: () {
                  setState(() => _eventCardDismissed = true);
                },
                onOpenEvent: () {
                  final int? eventId = eventInfo.eventId;
                  if (eventId == null) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailsScreen(eventId: eventId),
                    ),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: state.messages.when(
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: const [
                      _ThreadTopStateCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 30),
                            SizedBox(height: 12),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Start the conversation with your first message.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    final isMine =
                        myUserId != null && message.senderId == myUserId;

                    return _MessageBubbleCard(
                      message: message,
                      isMine: isMine,
                      isDark: isDark,
                      onReply: () => controller.setReplyingTo(message),
                      onDelete:
                          isMine ? () => controller.deleteMessage(message.id) : null,
                      onLike: () => controller.toggleLike(message),
                      onEdit: isMine
                          ? () => _showEditDialog(context, controller, message)
                          : null,
                    );
                  },
                );
              },
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _ThreadTopStateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try loading the conversation again.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: controller.load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChatReplyPreview(
                        message: state.replyingTo!,
                        onClose: controller.clearReplyingTo,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF17191D)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A303A)
                                  : const Color(0xFFE5EAF2),
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: state.sending
                                ? null
                                : (_) async {
                                    final ok = await controller.sendMessage(
                                      _messageController.text,
                                    );
                                    if (ok) _messageController.clear();
                                  },
                            decoration: const InputDecoration(
                              hintText: 'Write a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: state.sending
                              ? null
                              : () async {
                                  final ok = await controller.sendMessage(
                                    _messageController.text,
                                  );
                                  if (ok) _messageController.clear();
                                },
                          icon: state.sending
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ChatThreadController controller,
    MessageItem message,
  ) async {
    final textController = TextEditingController(text: message.content);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: textController,
          minLines: 2,
          maxLines: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    textController.dispose();

    if (result == null || result.isEmpty) return;
    await controller.editMessage(messageId: message.id, content: result);
  }

  void _showAttendeesSheet(
    BuildContext context,
    List<ChatParticipant> participants,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => AttendeesSheet(participants: participants),
    );
  }

  String _presenceLabel(List<ChatParticipant> participants) {
    final other = participants.cast<ChatParticipant?>().firstWhere(
          (p) => p != null && p.userId == widget.args.otherUserId,
          orElse: () => null,
        );

    if (other == null) return 'Chat';

    if (other.isOnline) return 'Online';
    if (other.lastActiveAt != null) {
      return 'Active ${_relativeTime(other.lastActiveAt!)}';
    }

    return 'Offline';
  }

  String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value.toLocal());

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MessageBubbleCard extends StatelessWidget {
  final MessageItem message;
  final bool isMine;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onEdit;
  final VoidCallback onReply;

  const _MessageBubbleCard({
    required this.message,
    required this.isMine,
    required this.isDark,
    this.onDelete,
    this.onLike,
    this.onEdit,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final senderName = (message.senderDisplayName?.trim().isNotEmpty ?? false)
        ? message.senderDisplayName!.trim()
        : 'User ${message.senderId}';

    final avatarUrl = (message.senderAvatarUrl?.trim().isNotEmpty ?? false)
        ? message.senderAvatarUrl!.trim()
        : null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        senderName.isNotEmpty
                            ? senderName.characters.first.toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  Material(
                    color: isMine
                        ? theme.colorScheme.primary.withValues(alpha: 0.14)
                        : (isDark
                            ? const Color(0xFF17191D)
                            : theme.colorScheme.surface),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onLongPress: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.reply_rounded),
                                  title: const Text('Reply'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onReply();
                                  },
                                ),
                                if (onEdit != null)
                                  ListTile(
                                    leading: const Icon(Icons.edit_rounded),
                                    title: const Text('Edit'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onEdit?.call();
                                    },
                                  ),
                                if (onLike != null)
                                  ListTile(
                                    leading: Icon(
                                      message.isLikedByMe
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                    ),
                                    title: Text(
                                      message.isLikedByMe ? 'Unlike' : 'Like',
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onLike?.call();
                                    },
                                  ),
                                if (onDelete != null)
                                  ListTile(
                                    leading:
                                        const Icon(Icons.delete_outline_rounded),
                                    title: const Text('Delete'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onDelete?.call();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isMine
                                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                                : isDark
                                    ? const Color(0xFF2A303A)
                                    : const Color(0xFFE5EAF2),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if ((message.replyPreview?.trim().isNotEmpty ?? false))
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.replySenderName ?? 'Reply',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.replyPreview!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              message.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.likesCount > 0) ...[
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    message.likesCount.toString(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (message.editedAt != null) ...[
                                  Text(
                                    'edited',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _formatTime(message.sentAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ThreadTopStateCard extends StatelessWidget {
  final Widget child;

  const _ThreadTopStateCard({required this.child});

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