import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/reports/models/report_target_type.dart';

class ReportTargetPreview extends StatelessWidget {
  final ReportTargetType targetType;
  final String? title;
  final String? subtitle;
  final String? imageUrl;

  const ReportTargetPreview({
    super.key,
    required this.targetType,
    this.title,
    this.subtitle,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    switch (targetType) {
      case ReportTargetType.comment:
        icon = Icons.mode_comment_outlined;
        break;
      case ReportTargetType.event:
        icon = Icons.event_outlined;
        break;
      case ReportTargetType.user:
        icon = Icons.person_outline_rounded;
        break;
      case ReportTargetType.review:
        icon = Icons.reviews_outlined;
        break;
    }

    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackIcon(icon: icon),
              ),
            )
          else
            _FallbackIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporting ${targetType.displayName.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title?.trim().isNotEmpty == true ? title! : 'Selected item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;

  const _FallbackIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: colorScheme.primary,
      ),
    );
  }
}