import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../../shared/reservations/models/organizer_reservation.dart';
import '../../../profile/presentation/screens/ticket_scanner_screen.dart';
import '../../application/event_reservations_controller.dart';
import 'public_profile_screen.dart';

final eventReservationsProvider =
    FutureProvider.family<EventReservationsViewData, int>((ref, eventId) async {
  final reservations = await ref
      .read(eventReservationsControllerProvider(eventId).notifier)
      .loadReservations();

  final userIds = reservations.map((e) => e.userId).toSet().toList();

  Map<int, PublicUserProfileDto> profiles = const {};
  if (userIds.isNotEmpty) {
    profiles = await ref.read(publicUsersApiProvider).getPublicProfiles(userIds);
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
  const EventReservationsScreen({
    super.key,
    required this.event,
  });

  final MyEventResponseDto event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(eventReservationsProvider(event.eventId));
    final controllerState =
        ref.watch(eventReservationsControllerProvider(event.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendees'),
        actions: [
          IconButton(
            tooltip: 'Open ticket scanner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TicketScannerScreen(
                    eventId: event.eventId,
                    eventTitle: event.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: AppAsyncView<EventReservationsViewData>(
        value: asyncValue,
        loading: const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (error, stackTrace) {
          return AppEmptyState(
            title: 'Failed to load attendees',
            message: error.toString(),
            actionLabel: 'Retry',
            onAction: () {
              ref.invalidate(eventReservationsProvider(event.eventId));
            },
            icon: Icons.cloud_off_rounded,
          );
        },
        empty: AppEmptyState(
          title: 'No attendees yet',
          message: 'Attendees for "${event.title}" will appear here.',
          icon: Icons.event_busy_rounded,
        ),
        isEmpty: (value) {
          final confirmedReservations = value.reservations
              .where((r) => r.status.trim().toLowerCase() == 'confirmed')
              .toList();
          return confirmedReservations.isEmpty;
        },
        data: (value) {
          final confirmedReservations = value.reservations
              .where((r) => r.status.trim().toLowerCase() == 'confirmed')
              .toList();

          final totalTickets = confirmedReservations.fold<int>(
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
              itemCount: confirmedReservations.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppSurfaceCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${confirmedReservations.length} attendee'
                          '${confirmedReservations.length == 1 ? '' : 's'} • '
                          '$totalTickets ticket${totalTickets == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                final item = confirmedReservations[index - 1];
                final profile = value.profilesByUserId[item.userId];

                final isRemoving = controllerState.removing &&
                    controllerState.removingReservationId == item.reservationId;

                final isCollectingCash =
                    controllerState.markingCashCollected &&
                        controllerState.cashCollectionReservationId ==
                            item.reservationId;

                return _ReservationCard(
                  reservation: item,
                  profile: profile,
                  isRemoving: isRemoving,
                  isCollectingCash: isCollectingCash,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          userId: item.userId,
                        ),
                      ),
                    );
                  },
                  onRemove: () => _removeAttendee(context, ref, item),
                  onCollectCash: () => _collectCash(context, ref, item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeAttendee(
    BuildContext context,
    WidgetRef ref,
    OrganizerReservationDto reservation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove attendee?'),
        content: const Text(
          'This will remove the attendee from the event and trigger the standard refund review flow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final controller =
        ref.read(eventReservationsControllerProvider(event.eventId).notifier);

    await controller.removeAttendee(
      reservation.reservationId,
      reason: 'Removed by organizer. Standard refund review required.',
    );

    ref.invalidate(eventReservationsProvider(event.eventId));

    final state = ref.read(eventReservationsControllerProvider(event.eventId));
    if (!context.mounted) return;

    if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendee removed and refund review requested.'),
      ),
    );
  }

  Future<void> _collectCash(
    BuildContext context,
    WidgetRef ref,
    OrganizerReservationDto reservation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark cash as received?'),
        content: Text(
          'This will mark ${reservation.totalAmount.toStringAsFixed(2)} ${reservation.currency} as collected in cash for this attendee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final controller =
        ref.read(eventReservationsControllerProvider(event.eventId).notifier);

    await controller.markCashCollected(reservation.reservationId);

    ref.invalidate(eventReservationsProvider(event.eventId));

    final state = ref.read(eventReservationsControllerProvider(event.eventId));
    if (!context.mounted) return;

    if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cash payment marked as received.'),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.profile,
    required this.onTap,
    required this.onRemove,
    required this.onCollectCash,
    required this.isRemoving,
    required this.isCollectingCash,
  });

  final OrganizerReservationDto reservation;
  final PublicUserProfileDto? profile;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onCollectCash;
  final bool isRemoving;
  final bool isCollectingCash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = _displayName(profile, reservation.userId);
    final subtitle = _subtitle(profile, reservation.userId);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
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
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                          if (reservation.confirmedAt != null)
                            _MetaChip(
                              icon: Icons.check_circle_outline_rounded,
                              label:
                                  'Confirmed ${_formatDate(reservation.confirmedAt!)}',
                            ),
                          if (reservation.isPayPalPaid)
                            const _StatusChip(
                              icon: Icons.verified_rounded,
                              label: 'Paid via PayPal',
                              tone: _StatusChipTone.success,
                            ),
                          if (reservation.isCashPending)
                            const _StatusChip(
                              icon: Icons.schedule_rounded,
                              label: 'Cash due at entry',
                              tone: _StatusChipTone.warning,
                            ),
                          if (reservation.isValidated)
                            _StatusChip(
                              icon: Icons.task_alt_rounded,
                              label: reservation.validatedAt != null
                                  ? 'Validated ${_formatDate(reservation.validatedAt!)}'
                                  : 'Ticket validated',
                              tone: _StatusChipTone.success,
                            ),
                        ],
                      ),
                      if ((reservation.paymentMessage ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          reservation.paymentMessage!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (reservation.canCollectCash && reservation.isCashPending)
                OutlinedButton.icon(
                  onPressed: isCollectingCash ? null : onCollectCash,
                  icon: isCollectingCash
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_rounded),
                  label: Text(
                    isCollectingCash ? 'Saving...' : 'Mark cash received',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: isRemoving ? null : onRemove,
                icon: isRemoving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_remove_rounded),
                label: Text(isRemoving ? 'Removing...' : 'Remove attendee'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _displayName(PublicUserProfileDto? profile, int userId) {
    if (profile == null) return 'User #$userId';

    final fullName = '${profile.firstName} ${profile.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;

    final username = profile.username.trim();
    if (username.isNotEmpty) return username;

    return 'User #$userId';
  }

  static String _subtitle(PublicUserProfileDto? profile, int userId) {
    if (profile == null) return 'Tap to view profile';

    final username = profile.username.trim();
    if (username.isNotEmpty) return '@$username';

    return 'User #$userId';
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
  const _AvatarBubble({
    required this.imageUrl,
    required this.label,
  });

  final String? imageUrl;
  final String label;

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
      backgroundColor: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.12),
      child: Text(
        _initials(label),
        style: const TextStyle(fontWeight: FontWeight.w700),
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
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
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

enum _StatusChipTone { neutral, success, warning }

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.tone = _StatusChipTone.neutral,
  });

  final IconData icon;
  final String label;
  final _StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    final Color border;

    switch (tone) {
      case _StatusChipTone.success:
        background = Colors.green.withValues(alpha: 0.12);
        foreground = Colors.green.shade800;
        border = Colors.green.withValues(alpha: 0.24);
        break;
      case _StatusChipTone.warning:
        background = Colors.amber.withValues(alpha: 0.16);
        foreground = Colors.orange.shade900;
        border = Colors.amber.withValues(alpha: 0.28);
        break;
      case _StatusChipTone.neutral:
        background = scheme.surfaceContainerHighest.withValues(alpha: 0.5);
        foreground = scheme.onSurface;
        border = scheme.outlineVariant.withValues(alpha: 0.4);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}