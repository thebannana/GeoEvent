import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import 'comment_avatar.dart';

class CommentComposer extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isEditing;
  final bool isReplying;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCancelMode;
  final String? currentUserAvatarUrl;
  final String currentUserDisplayName;
  final String? Function(String?) validator;
  final AutovalidateMode autovalidateMode;
  final String? submitDisabledReason;

  const CommentComposer({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isEditing,
    required this.isReplying,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onChanged,
    required this.currentUserAvatarUrl,
    required this.currentUserDisplayName,
    required this.validator,
    required this.autovalidateMode,
    required this.submitDisabledReason,
    this.onCancelMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit = !isSubmitting && controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onCancelMode != null)
          ComposerStateBanner(
            isEditing: isEditing,
            onCancel: onCancelMode!,
          ),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommentAvatar(
                    size: 36,
                    avatarUrl: currentUserAvatarUrl,
                    fallbackText: currentUserDisplayName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.22),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        enabled: !isSubmitting,
                        textInputAction: TextInputAction.newline,
                        autovalidateMode: autovalidateMode,
                        validator: validator,
                        onChanged: onChanged,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: isEditing
                              ? 'Edit your comment...'
                              : isReplying
                                  ? 'Write a reply...'
                                  : 'Add a comment...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: submitDisabledReason ??
                        (isEditing ? 'Save comment' : 'Post comment'),
                    child: FilledButton(
                      onPressed: canSubmit ? onSubmit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: isSubmitting
                          ? const AppSpinner(
                              size: 16,
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(isEditing ? 'Save' : 'Post'),
                    ),
                  ),
                ],
              ),
              if (submitDisabledReason != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: Text(
                    submitDisabledReason!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ComposerStateBanner extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onCancel;

  const ComposerStateBanner({
    super.key,
    required this.isEditing,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_outlined : Icons.reply_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing ? 'Editing comment' : 'Replying to comment',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}