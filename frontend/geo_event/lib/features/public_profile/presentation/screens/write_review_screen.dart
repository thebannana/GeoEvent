import 'package:flutter/material.dart';

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
      await widget.onSave(rating!, commentController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> deleteReview() async {
    if (widget.onDelete == null || isBusy) return;

    setState(() => isBusy = true);
    try {
      await widget.onDelete!();
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave a review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                final active = (rating ?? 0) >= star;
                return IconButton(
                  onPressed: isBusy ? null : () => setState(() => rating = star),
                  icon: Icon(
                    active ? Icons.star_rounded : Icons.star_border_rounded,
                    color: active ? const Color(0xFFFFC857) : Colors.grey,
                  ),
                );
              }),
            ),
            TextField(
              controller: commentController,
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Write your review (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy ? null : save,
                child: isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }
}