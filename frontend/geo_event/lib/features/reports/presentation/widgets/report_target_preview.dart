import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/reports/models/report_target_type.dart';

class ReportTargetPreview extends StatelessWidget {
  static const String _defaultTitle = 'Selected item';

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
    final resolvedIcon = _iconForTargetType(targetType);
    final resolvedTitle =
        title?.trim().isNotEmpty == true ? title!.trim() : _defaultTitle;
    final resolvedSubtitle =
        subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : null;
    final resolvedImageUrl =
        imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null;

    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (resolvedImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                resolvedImageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _FallbackIcon(icon: resolvedIcon),
              ),
            )
          else
            _FallbackIcon(icon: resolvedIcon),
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
                  resolvedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (resolvedSubtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    resolvedSubtitle,
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

  IconData _iconForTargetType(ReportTargetType type) {
    switch (type) {
      case ReportTargetType.comment:
        return Icons.mode_comment_outlined;
      case ReportTargetType.event:
        return Icons.event_outlined;
      case ReportTargetType.user:
        return Icons.person_outline_rounded;
      case ReportTargetType.review:
        return Icons.reviews_outlined;
    }
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;

  const _FallbackIcon({
    required this.icon,
  });

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