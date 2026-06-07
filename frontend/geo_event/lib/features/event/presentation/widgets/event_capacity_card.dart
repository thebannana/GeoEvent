import 'package:flutter/material.dart';

class AttendeePreviewUser {
  final int userId;
  final String label;
  final String? avatarUrl;

  const AttendeePreviewUser({
    required this.userId,
    required this.label,
    this.avatarUrl,
  });
}

class EventCapacityCard extends StatelessWidget {
  final int capacity;
  final int reservedCount;
  final int attendeeCount;
  final List<AttendeePreviewUser> previewUsers;
  final VoidCallback? onViewAttendeesTap;

  const EventCapacityCard({
    super.key,
    required this.capacity,
    required this.reservedCount,
    required this.attendeeCount,
    this.previewUsers = const [],
    this.onViewAttendeesTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeCapacity = capacity <= 0 ? 1 : capacity;
    final normalizedReserved = reservedCount.clamp(0, safeCapacity);
    final progress = (normalizedReserved / safeCapacity).clamp(0.0, 1.0);
    final left = (capacity - normalizedReserved).clamp(0, capacity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Capacity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$reservedCount / $capacity',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9
                    ? const Color(0xFFFF7A59)
                    : const Color(0xFF67B8FF),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                left <= 0 ? 'Sold out' : '$left spots left',
                style: TextStyle(
                  color: left <= 0 ? const Color(0xFFFF8A80) : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$attendeeCount attendees',
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (previewUsers.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: Stack(
                children: [
                  for (int i = 0; i < previewUsers.take(5).length; i++)
                    Positioned(
                      left: i * 22,
                      child: _UserAvatar(user: previewUsers[i]),
                    ),
                  if (previewUsers.length > 5)
                    Positioned(
                      left: 5 * 22,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF273446),
                        child: Text(
                          '+${previewUsers.length - 5}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewAttendeesTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'View attendees',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AttendeePreviewUser user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl?.trim() ?? '';

    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF1D222B),
      child: avatarUrl.isNotEmpty
          ? CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage(avatarUrl),
            )
          : CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF273446),
              child: Text(
                _initials(user.label),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}