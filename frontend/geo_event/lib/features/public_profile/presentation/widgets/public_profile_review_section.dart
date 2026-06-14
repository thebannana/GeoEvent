import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/public_profile/models/user_review.dart';

class PublicProfileReviewsSection extends StatelessWidget {
  final List<UserReview> reviews;

  const PublicProfileReviewsSection({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No written reviews yet.'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.value
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 18,
                          color: const Color(0xFFFFC857),
                        ),
                      ),
                    ),
                    if ((review.comment ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(review.comment!.trim()),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}