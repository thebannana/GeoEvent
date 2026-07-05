import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/models/message_item.dart';
import 'chat_avatar.dart';

class ChatMessageBubble extends StatefulWidget {
  final MessageItem message;
  final bool isMine;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onEdit;
  final VoidCallback onReply;
  final ChatThreadType threadType;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onDelete,
    this.onLike,
    this.onEdit,
    required this.onReply,
    this.threadType = ChatThreadType.direct,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  double _dragDx = 0;

  static const double _replyTrigger = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textMuted = theme.textTheme.bodySmall?.color;

    final senderName = _safeSenderName(
      widget.message.senderDisplayName,
    );

    final avatarUrl =
        (widget.message.senderAvatarUrl?.trim().isNotEmpty ?? false)
            ? widget.message.senderAvatarUrl!.trim()
            : null;

    final replySender = _safeReplySenderName(
      widget.message.replySenderName,
      widget.message.senderDisplayName,
    );

    final bubbleColor = widget.isMine
        ? colorScheme.primary.withValues(alpha: 0.14)
        : colorScheme.surface;

    final bubbleBorderColor = widget.isMine
        ? colorScheme.primary.withValues(alpha: 0.18)
        : colorScheme.outline.withValues(alpha: 0.28);

    return Align(
      alignment:
          widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMine) ...[
              ChatAvatar(
                title: senderName,
                imageUrl: avatarUrl,
                size: 32,
                type: widget.threadType,
                showPresence: false,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!widget.isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ),
                  Stack(
                    alignment: widget.isMine
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    children: [
                      Positioned(
                        left: widget.isMine ? 8 : null,
                        right: widget.isMine ? null : 8,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 140),
                          opacity: _dragDx.abs() > 18 ? 1 : 0,
                          child: Icon(
                            Icons.reply_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(_dragDx, 0, 0),
                        child: GestureDetector(
                          onDoubleTap: widget.onLike,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              if (widget.isMine) {
                                _dragDx = (_dragDx + details.delta.dx)
                                    .clamp(-_replyTrigger, 0);
                              } else {
                                _dragDx = (_dragDx + details.delta.dx)
                                    .clamp(0, _replyTrigger);
                              }
                            });
                          },
                          onHorizontalDragEnd: (_) {
                            final reachedReply =
                                _dragDx.abs() >= _replyTrigger * 0.72;
                            setState(() => _dragDx = 0);
                            if (reachedReply) {
                              widget.onReply();
                            }
                          },
                          onHorizontalDragCancel: () {
                            setState(() => _dragDx = 0);
                          },
                          onLongPress: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              builder: (_) => AppBottomSheetContainer(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.reply_rounded),
                                      title: const Text('Reply'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onReply();
                                      },
                                    ),
                                    if (widget.onEdit != null)
                                      ListTile(
                                        leading: const Icon(Icons.edit_rounded),
                                        title: const Text('Edit'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          widget.onEdit?.call();
                                        },
                                      ),
                                    if (widget.onLike != null)
                                      ListTile(
                                        leading: Icon(
                                          widget.message.isLikedByMe
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                        ),
                                        title: Text(
                                          widget.message.isLikedByMe
                                              ? 'Unlike'
                                              : 'Like',
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          widget.onLike?.call();
                                        },
                                      ),
                                    if (widget.onDelete != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        title: const Text('Delete'),
                                        subtitle: const Text(
                                          'This action cannot be undone.',
                                        ),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final confirmed =
                                              await AppConfirmDialog.show(
                                            context,
                                            title: 'Delete message?',
                                            message:
                                                'This message will be permanently deleted. This action cannot be undone.',
                                            confirmLabel: 'Delete',
                                          );
                                          if (confirmed == true) {
                                            widget.onDelete?.call();
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Material(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: bubbleBorderColor,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                              child: Column(
                                crossAxisAlignment: widget.isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (widget.message.replyPreview
                                          ?.trim()
                                          .isNotEmpty ??
                                      false)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            replySender,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.message.replyPreview!,
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
                                    widget.message.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.message.likesCount > 0) ...[
                                        Icon(
                                          Icons.favorite_rounded,
                                          size: 13,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.message.likesCount.toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (widget.message.editedAt != null) ...[
                                        Text(
                                          'Edited',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        widget.message.sentAt.formatTime(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _safeSenderName(String? displayName) {
    final cleanedDisplayName = displayName?.trim();
    if (cleanedDisplayName != null && cleanedDisplayName.isNotEmpty) {
      return cleanedDisplayName;
    }

    return 'User';
  }

  static String _safeReplySenderName(
    String? replySenderName,
    String? senderDisplayName,
  ) {
    final cleanedReplySender = replySenderName?.trim();
    if (cleanedReplySender != null && cleanedReplySender.isNotEmpty) {
      return cleanedReplySender;
    }

    return _safeSenderName(senderDisplayName);
  }
}