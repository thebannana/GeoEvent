import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../../shared/reservations/data/organizer_reservations_api.dart';
import '../../../../shared/reservations/models/organizer_reservation.dart';
import 'public_profile_screen.dart';

class EventReservationsScreen extends ConsumerStatefulWidget {
  final MyEventResponseDto event;

  const EventReservationsScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventReservationsScreen> createState() =>
      _EventReservationsScreenState();
}

class _EventReservationsScreenState
    extends ConsumerState<EventReservationsScreen> {
  bool _loading = true;
  String? _error;
  List<OrganizerReservationDto> _reservations = const [];
  Map<int, PublicUserProfileDto> _profilesByUserId = const {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final reservations = await ref
          .read(organizerReservationsApiProvider)
          .getEventReservations(widget.event.eventId);

      final userIds = reservations.map((e) => e.userId).toSet().toList();

      Map<int, PublicUserProfileDto> profiles = const {};

      if (userIds.isNotEmpty) {
        profiles =
            await ref.read(publicUsersApiProvider).getPublicProfiles(userIds);
      }

      if (!mounted) return;

      setState(() {
        _reservations = reservations;
        _profilesByUserId = profiles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _TopStateCard(
                        icon: Icons.cloud_off_rounded,
                        title: 'Failed to load reservations',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _load,
                      ),
                    ],
                  )
                : _reservations.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _TopStateCard(
                            icon: Icons.event_busy_rounded,
                            title: 'No reservations yet',
                            subtitle:
                                'Reservations for "${widget.event.title}" will appear here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _reservations.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final totalTickets = _reservations.fold<int>(
                              0,
                              (sum, item) => sum + item.quantity,
                            );

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF17191D)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2A303A)
                                      : const Color(0xFFE5EAF2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_reservations.length} reservation${_reservations.length == 1 ? '' : 's'} • $totalTickets ticket${totalTickets == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final item = _reservations[index - 1];
                          final profile = _profilesByUserId[item.userId];

                          return _ReservationCard(
                            reservation: item,
                            profile: profile,
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PublicProfileScreen(userId: item.userId),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final OrganizerReservationDto reservation;
  final PublicUserProfileDto? profile;
  final bool isDark;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.profile,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(reservation.status);
    final displayName = _displayName(profile, reservation.userId);
    final subtitle = _subtitle(profile, reservation.userId);

    return Material(
      color: isDark ? const Color(0xFF17191D) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE5EAF2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBubble(
                imageUrl: profile?.imageUrl,
                label: displayName,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _normalizedStatus(reservation.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Qty ${reservation.quantity}',
                        ),
                        _MetaChip(
                          icon: Icons.payments_outlined,
                          label:
                              '${reservation.totalAmount.toStringAsFixed(2)} ${reservation.currency}',
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: _formatDate(reservation.createdAt),
                        ),
                        if (reservation.confirmedAt != null)
                          _MetaChip(
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                'Confirmed ${_formatDate(reservation.confirmedAt!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _displayName(PublicUserProfileDto? profile, int userId) {
    if (profile == null) return 'User #$userId';

    final fullName = '${profile.firstName} ${profile.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (profile.username.trim().isNotEmpty) return profile.username.trim();

    return 'User #$userId';
  }

  static String _subtitle(PublicUserProfileDto? profile, int userId) {
    if (profile == null) return 'Tap to view profile';

    if (profile.username.trim().isNotEmpty) {
      return '@${profile.username}';
    }

    return 'User #$userId';
  }

  static String _normalizedStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'refunded':
        return 'Refunded';
      default:
        return status.trim().isEmpty ? 'Unknown' : status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF43A047);
      case 'pending':
        return const Color(0xFFF0A500);
      case 'cancelled':
        return const Color(0xFFE05C5C);
      case 'expired':
        return const Color(0xFF8E6AD8);
      case 'refunded':
        return const Color(0xFF5B9ED6);
      default:
        return const Color(0xFF5B9ED6);
    }
  }

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} • $hour:$minute';
  }
}

class _AvatarBubble extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final bool isDark;

  const _AvatarBubble({
    required this.imageUrl,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(normalizedUrl),
        backgroundColor:
            isDark ? const Color(0xFF22252B) : const Color(0xFFF1F4F8),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor:
          isDark ? const Color(0xFF22252B) : const Color(0xFFF1F4F8),
      child: Text(
        _initials(label),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}