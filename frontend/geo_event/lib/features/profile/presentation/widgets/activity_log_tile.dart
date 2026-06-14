import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/profile/models/activity_log.dart';

class ActivityLogTile extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogTile({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForAction(log.actionType),
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForLog(log),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleForLog(log),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDateTime(log.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  IconData _iconForAction(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'login':
        return Icons.login_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'register':
        return Icons.person_add_alt_1_rounded;
      case 'profileupdate':
      case 'profile_update':
        return Icons.manage_accounts_rounded;
      case 'purchase':
        return Icons.receipt_long_rounded;
      case 'bookmark':
        return Icons.bookmark_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'view':
      default:
        return Icons.visibility_rounded;
    }
  }

  String _titleForLog(ActivityLog log) {
    final action = _humanize(log.actionType);
    final target = _humanize(log.targetType);

    if (target.isEmpty) return action;
    return '$action · $target';
  }

  String _subtitleForLog(ActivityLog log) {
    final details = <String>[
      if (log.targetId > 0) 'Target #${log.targetId}',
      if (log.metadata.trim().isNotEmpty) log.metadata.trim(),
    ];

    if (details.isEmpty) return 'No additional details';
    return details.join(' • ');
  }

  String _humanize(String value) {
    if (value.trim().isEmpty) return '';

    final normalized = value
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .trim()
        .toLowerCase();

    return normalized
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy\n$hh:$min';
  }
}