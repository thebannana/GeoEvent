import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/chat/models/chat_participant.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_state.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/models/message_item.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../../public_profile/presentation/screens/public_profile_screen.dart';
import '../../application/chat_thread_controller.dart';
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
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  bool eventCardDismissed = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual<ChatThreadState>(
      chatThreadControllerProvider(widget.args),
      (previous, next) {
        final previousCount = previous?.messages.valueOrNull?.length ?? 0;
        final nextCount = next.messages.valueOrNull?.length ?? 0;

        if (nextCount > previousCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!scrollController.hasClients) return;
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatThreadControllerProvider(widget.args));
    final controller =
        ref.read(chatThreadControllerProvider(widget.args).notifier);
    final myUserId = ref.watch(sessionUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: state.details.when(
          data: (details) => ChatThreadHeader(details: details),
          error: (_, _) => Text(widget.args.title),
          loading: () => Text(widget.args.title),
        ),
        actions: [
          state.details.maybeWhen(
            data: (details) {
              return IconButton(
                tooltip: 'Chat details',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailsScreen(
                        details: details,
                        currentUserId: myUserId,
                        onLeaveThread: () async {
                          await controller.leaveThread();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
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
              if (eventInfo == null || eventCardDismissed) {
                return const SizedBox.shrink();
              }

              return EventChatInfoCard(
                info: eventInfo,
                onClose: () => setState(() => eventCardDismissed = true),
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
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: const [
                      ThreadTopStateCard(
                        child: AppEmptyState(
                          title: 'No messages yet',
                          message:
                              'Start the conversation with your first message.',
                          icon: Icons.chat_bubble_outline_rounded,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    final isMine =
                        myUserId != null && message.senderId == myUserId;

                    return ChatMessageBubble(
                      message: message,
                      isMine: isMine,
                      threadType: state.details.valueOrNull?.eventInfo != null
                          ? ChatThreadType.eventGroup
                          : widget.args.type,
                      onReply: () => controller.setReplyingTo(message),
                      onDelete: isMine ? () => controller.deleteMessage(message.id) : null,
                      onLike: () => controller.toggleLike(message),
                      onEdit: isMine
                          ? () => showEditDialog(context, controller, message)
                          : null,
                    );
                  },
                );
              },
              error: (_, _) => ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  ThreadTopStateCard(
                    child: AppErrorState(
                      title: 'Failed to load messages',
                      message: 'Try loading the conversation again.',
                      onRetry: controller.load,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: AppSpinner(size: 28, strokeWidth: 2.8),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.20),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: TextField(
                            controller: messageController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: state.sending
                                ? null
                                : (_) async {
                                    final ok = await controller.sendMessage(
                                      messageController.text,
                                    );
                                    if (ok) {
                                      messageController.clear();
                                      jumpToBottom();
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
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FilledButton(
                          onPressed: state.sending
                              ? null
                              : () async {
                                  final ok = await controller.sendMessage(
                                    messageController.text,
                                  );
                                  if (ok) {
                                    messageController.clear();
                                    jumpToBottom();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: state.sending
                              ? AppSpinner(
                                  size: 18,
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: theme.colorScheme.onPrimary,
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

  void jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> showEditDialog(
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

class ThreadTopStateCard extends StatelessWidget {
  final Widget child;

  const ThreadTopStateCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}