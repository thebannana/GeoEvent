import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_details.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/models/message_item.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../../public_profile/presentation/screens/public_profile_screen.dart';
import '../../application/chat_thread_controller.dart';
import '../../application/messages_controller.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_reply_preview.dart';
import '../widgets/chat_thread_header.dart';
import '../widgets/event_chat_info_card.dart';
import 'chat_details_screen.dart';

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
  final _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadControllerProvider(widget.args));
    final controller =
        ref.read(chatThreadControllerProvider(widget.args).notifier);
    final myUserId = ref.watch(authStateProvider).user?.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(chatThreadControllerProvider(widget.args), (previous, next) {
      final previousCount = previous?.messages.valueOrNull?.length ?? 0;
      final nextCount = next.messages.valueOrNull?.length ?? 0;

      if (nextCount > previousCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: state.details.when(
          data: (details) => ChatThreadHeader(details: details),
          error: (_, __) => Text(widget.args.title),
          loading: () => Text(widget.args.title),
        ),
        actions: [
          state.details.maybeWhen(
            data: (details) {
              final isEventGroup = _isEventGroup(details);

              return IconButton(
                tooltip: 'Chat details',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailsScreen(
                        details: details,
                        currentUserId: myUserId,
                        onLeaveGroup: isEventGroup
                            ? () => controller.leaveGroup()
                            : null,
                        onOpenEventDetails: details.eventInfo == null
                            ? null
                            : () {
                                final eventId = details.eventInfo!.eventId;
                                if (eventId <= 0) return;

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailsScreen(eventId: eventId),
                                  ),
                                );
                              },
                        onOpenParticipant: (ChatParticipant participant) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: participant.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded),
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
                  final eventId = eventInfo.eventId;
                  if (eventId <= 0) return;

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
                    controller: _scrollController,
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
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    final isMine =
                        myUserId != null && message.senderId == myUserId;

                    return ChatMessageBubble(
                      message: message,
                      isMine: isMine,
                      isDark: isDark,
                      onReply: () => controller.setReplyingTo(message),
                      onDelete: isMine
                          ? () => controller.deleteMessage(message.id)
                          : null,
                      onLike: () => controller.toggleLike(message),
                      onEdit: isMine
                          ? () => _showEditDialog(context, controller, message)
                          : null,
                    );
                  },
                );
              },
              error: (_, __) => ListView(
                controller: _scrollController,
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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
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
                    color: Theme.of(context).dividerColor.withOpacity(0.08),
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
                                    if (ok) {
                                      _messageController.clear();
                                      _jumpToBottom();
                                    }
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
                                  if (ok) {
                                    _messageController.clear();
                                    _jumpToBottom();
                                  }
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

  bool _isEventGroup(ChatThreadDetails details) {
    if (details.eventInfo != null) return true;
    if (details.type == ChatThreadType.eventGroup) return true;
    if (details.participants.length > 2) return true;
    return false;
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
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