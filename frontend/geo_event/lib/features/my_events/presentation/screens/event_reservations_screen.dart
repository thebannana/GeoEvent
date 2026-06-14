import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_async_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../../shared/reservations/data/organizer_reservations_api.dart';
import '../../../../shared/reservations/models/organizer_reservation.dart';
import 'public_profile_screen.dart';

final eventReservationsProvider =
    FutureProvider.family<EventReservationsViewData, int>((ref, eventId) async {
  final reservations = await ref
      .watch(organizerReservationsApiProvider)
      .getEventReservations(eventId);

  final userIds = reservations.map((e) => e.userId).toSet().toList();

  Map<int, PublicUserProfileDto> profiles = const {};
  if (userIds.isNotEmpty) {
    profiles = await ref.watch(publicUsersApiProvider).getPublicProfiles(userIds);
  }

  return EventReservationsViewData(
    reservations: reservations,
    profilesByUserId: profiles,
  );
});

class EventReservationsViewData {
  final List<OrganizerReservationDto> reservations;
  final Map<int, PublicUserProfileDto> profilesByUserId;

  const EventReservationsViewData({
    required this.reservations,
    required this.profilesByUserId,
  });
}

class EventReservationsScreen extends ConsumerWidget {
  final MyEventResponseDto event;

  const EventReservationsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(eventReservationsProvider(event.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
      ),
      body: AppAsyncView<EventReservationsViewData>(
        value: asyncValue,
        loading: const Center(child: CircularProgressIndicator()),
        errorBuilder: (error, stackTrace) {
          return AppEmptyState(
            title: 'Failed to load reservations',
            message: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(eventReservationsProvider(event.eventId)),
            icon: Icons.cloud_off_rounded,
          );
        },
        empty: AppEmptyState(
          title: 'No reservations yet',
          message: 'Reservations for "${event.title}" will appear here.',
          icon: Icons.event_busy_rounded,
        ),
        isEmpty: (value) => value.reservations.isEmpty,
        data: (value) {
          final totalTickets = value.reservations.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventReservationsProvider(event.eventId));
              await ref.read(eventReservationsProvider(event.eventId).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: value.reservations.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppSurfaceCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${value.reservations.length} reservation'
                          '${value.reservations.length == 1 ? '' : 's'} • '
                          '$totalTickets ticket${totalTickets == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                final item = value.reservations[index - 1];
                final profile = value.profilesByUserId[item.userId];

                return _ReservationCard(
                  reservation: item,
                  profile: profile,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: item.userId),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final OrganizerReservationDto reservation;
  final PublicUserProfileDto? profile;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(reservation.status);
    final displayName = _displayName(profile, reservation.userId);
    final subtitle = _subtitle(profile, reservation.userId);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarBubble(
            imageUrl: profile?.imageUrl,
            label: displayName,
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
                        style: theme.textTheme.titleSmall?.copyWith(
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
                  style: theme.textTheme.bodySmall,
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
    if (profile.username.trim().isNotEmpty) return '@${profile.username}';
    return 'User #$userId';
  }

  static String _normalizedStatus(String status) {
    switch (status.trim().toLowerCase()) {
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
        return const Color(0xFF5B9ED6);
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

  const _AvatarBubble({
    required this.imageUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(normalizedUrl),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      child: Text(
        _initials(label),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}