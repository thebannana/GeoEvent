import 'package:flutter/material.dart';

import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';

class EventShareSheet extends StatelessWidget {
  final EventItem item;
  final VoidCallback onCopyLink;
  final VoidCallback onSystemShare;
  final VoidCallback onSendInChat;

  const EventShareSheet({
    super.key,
    required this.item,
    required this.onCopyLink,
    required this.onSystemShare,
    required this.onSendInChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final imageUrl = (item.coverImageUrl ?? '').trim().isNotEmpty
        ? item.coverImageUrl!.trim()
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : null);

    final locationText = '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}';

    return AppBottomSheetContainer(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null && imageUrl.trim().isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _shareImageFallback(context),
                      )
                    : _shareImageFallback(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ShareActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: onSystemShare,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShareActionButton(
                  icon: Icons.link_rounded,
                  label: 'Copy link',
                  onTap: onCopyLink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShareActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Send',
                  onTap: onSendInChat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareImageFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.event,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class ShareActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ShareActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.onSurface, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}