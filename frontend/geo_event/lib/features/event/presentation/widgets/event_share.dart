import 'package:flutter/material.dart';

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
    final imageUrl = (item.coverImageUrl ?? '').trim().isNotEmpty
        ? item.coverImageUrl!.trim()
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : null);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
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
                          errorBuilder: (_, __, ___) => _shareImageFallback(),
                        )
                      : _shareImageFallback(),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isOnline
                            ? 'Online event'
                            : (item.venueName?.trim().isNotEmpty == true
                                ? item.venueName!.trim()
                                : 'Location TBA'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
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
                  foregroundColor: Colors.white70,
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
      ),
    );
  }

  Widget _shareImageFallback() {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.event,
        color: Colors.white70,
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
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}