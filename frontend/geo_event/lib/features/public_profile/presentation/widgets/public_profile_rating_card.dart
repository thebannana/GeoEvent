import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PublicProfileRatingCard extends StatelessWidget {
  final double averageRating;
  final int ratingsCount;
  final int? myRating;
  final String? myReviewComment;
  final bool isSubmitting;
  final ValueChanged<int> onRatingSelected;
  final VoidCallback onWriteReviewTap;

  const PublicProfileRatingCard({
    super.key,
    required this.averageRating,
    required this.ratingsCount,
    required this.myRating,
    required this.myReviewComment,
    required this.isSubmitting,
    required this.onRatingSelected,
    required this.onWriteReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.color;
    final hasReview = myReviewComment?.trim().isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile rating',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              myRating == null
                  ? 'Tap a star to rate this profile.'
                  : 'Your rating: $myRating/5',
              style: TextStyle(
                fontSize: 13,
                color: muted,
              ),
            ),
            if (hasReview) ...[
              const SizedBox(height: 8),
              Text(
                myReviewComment!.trim(),
                style: TextStyle(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 2,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final active = myRating != null && starValue <= myRating!;

                return IconButton(
                  onPressed:
                      isSubmitting ? null : () => onRatingSelected(starValue),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Rate $starValue out of 5',
                  icon: Icon(
                    active ? Icons.star_rounded : Icons.star_border_rounded,
                    color: active
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  ratingsCount == 0 ? '—' : averageRating.toStringAsFixed(1),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ratingsCount == 0
                        ? 'No ratings yet'
                        : '$ratingsCount rating${ratingsCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: muted,
                    ),
                  ),
                ),
                if (isSubmitting)
                  const AppSpinner(
                    size: 16,
                    strokeWidth: 2,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isSubmitting ? null : onWriteReviewTap,
              child: Text(hasReview ? 'Edit review' : 'Write review'),
            ),
          ],
        ),
      ),
    );
  }
}