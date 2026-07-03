import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';

class WriteReviewScreen extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;
  final bool canDelete;
  final Future<void> Function(int rating, String? comment) onSave;
  final Future<void> Function()? onDelete;

  const WriteReviewScreen({
    super.key,
    required this.initialRating,
    required this.initialComment,
    required this.canDelete,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int? rating;
  late final TextEditingController commentController;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
    commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (rating == null || isBusy) return;

    setState(() => isBusy = true);
    try {
      await widget.onSave(
        rating!,
        commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isBusy = false);
      }
    }
  }

  Future<void> deleteReview() async {
    if (widget.onDelete == null || isBusy) return;

    setState(() => isBusy = true);
    try {
      await widget.onDelete!();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSave = rating != null && !isBusy;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Write review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave a review',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final active = (rating ?? 0) >= star;

                    return IconButton(
                      tooltip: 'Rate $star out of 5',
                      onPressed:
                          isBusy ? null : () => setState(() => rating = star),
                      icon: Icon(
                        active
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: active
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                        size: 30,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 1000,
                  enabled: !isBusy,
                  decoration: const InputDecoration(
                    hintText: 'Write your review (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSave ? save : null,
                    child: isBusy
                        ? const AppSpinner(
                            size: 18,
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text('Save review'),
                  ),
                ),
                if (widget.canDelete) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : deleteReview,
                      child: const Text('Delete review'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}