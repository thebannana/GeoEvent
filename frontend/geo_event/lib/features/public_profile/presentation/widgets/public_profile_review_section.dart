import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/public_profile/models/user_review.dart';
import '../../../profile/presentation/widgets/list_paging_footer.dart';

class PublicProfileReviewsSection extends StatelessWidget {
  final List<UserReview> reviews;
  final bool hasNextPage;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const PublicProfileReviewsSection({
    super.key,
    required this.reviews,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Text(
              'No written reviews yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...reviews.map((review) {
              final displayName = review.reviewerDisplayName.trim().isNotEmpty
                  ? review.reviewerDisplayName.trim()
                  : '@${review.reviewerUsername}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.createdAt.formatDate(pattern: 'dd.MM.yyyy.'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review.value
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 18,
                            color: index < review.value
                                ? colorScheme.tertiary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if ((review.comment ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          review.comment!.trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          ListPagingFooter(
            isLoadingMore: isLoadingMore,
            hasMore: hasNextPage,
            loadedCount: reviews.length,
            totalCount: reviews.length,
            itemLabel: 'reviews',
            onLoadMore: hasNextPage && !isLoadingMore ? onLoadMore : null,
          ),
        ],
      ),
    );
  }
}