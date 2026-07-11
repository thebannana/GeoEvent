import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/event_reservations/models/organizer_reservation.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../event/presentation/widgets/user_initials.dart';

class EventReservationCard extends StatelessWidget {
  const EventReservationCard({
    super.key,
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
                _AttendeeAvatar(
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
                          _ReservationMetaChip(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Qty ${reservation.quantity}',
                          ),
                          _ReservationMetaChip(
                            icon: Icons.payments_outlined,
                            label: PriceFormatter.format(
                              reservation.totalAmount,
                              currency: reservation.currency,
                            ),
                          ),
                          if (reservation.confirmedAt != null)
                            _ReservationMetaChip(
                              icon: Icons.check_circle_outline_rounded,
                              label:
                                  'Confirmed ${reservation.confirmedAt!.formatDateTime(pattern: 'dd.MM.yyyy • HH:mm')}',
                            ),
                          if (reservation.isPayPalPaid)
                            const _ReservationStatusChip(
                              icon: Icons.verified_rounded,
                              label: 'Paid via PayPal',
                              tone: _ReservationStatusTone.success,
                            ),
                          if (reservation.isCashPending)
                            const _ReservationStatusChip(
                              icon: Icons.schedule_rounded,
                              label: 'Cash due at entry',
                              tone: _ReservationStatusTone.warning,
                            ),
                            if (reservation.hasPendingRefundRequest)
                            const _ReservationStatusChip(
                              icon: Icons.undo_rounded,
                              label: 'Refund under admin review',
                              tone: _ReservationStatusTone.warning,
                            ),
                          if (reservation.isValidated)
                            _ReservationStatusChip(
                              icon: Icons.task_alt_rounded,
                              label: reservation.validatedAt != null
                                  ? 'Validated ${reservation.validatedAt!.formatDateTime(pattern: 'dd.MM.yyyy • HH:mm')}'
                                  : 'Ticket validated',
                              tone: _ReservationStatusTone.success,
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
                      ? const AppSpinner(size: 16, strokeWidth: 2)
                      : const Icon(Icons.payments_rounded),
                  label: Text(
                    isCollectingCash ? 'Saving...' : 'Mark cash received',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: isRemoving ? null : onRemove,
                icon: isRemoving
                    ? const AppSpinner(size: 16, strokeWidth: 2)
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
}

class _AttendeeAvatar extends StatelessWidget {
  const _AttendeeAvatar({
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
        onBackgroundImageError: (error, stackTrace) {
          AppLogger.warning(
            'Failed to load attendee avatar: $normalizedUrl',
            tag: 'EventReservationCard',
          );
        },
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.12),
      child: Text(
        UserInitials.from(label, fallback: '?'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReservationMetaChip extends StatelessWidget {
  const _ReservationMetaChip({
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

enum _ReservationStatusTone { neutral, success, warning }

class _ReservationStatusChip extends StatelessWidget {
  const _ReservationStatusChip({
    required this.icon,
    required this.label,
    this.tone = _ReservationStatusTone.neutral,
  });

  final IconData icon;
  final String label;
  final _ReservationStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    final Color border;

    switch (tone) {
      case _ReservationStatusTone.success:
        background = Colors.green.withValues(alpha: 0.12);
        foreground = Colors.green.shade800;
        border = Colors.green.withValues(alpha: 0.24);
        break;
      case _ReservationStatusTone.warning:
        background = Colors.amber.withValues(alpha: 0.16);
        foreground = Colors.orange.shade900;
        border = Colors.amber.withValues(alpha: 0.28);
        break;
      case _ReservationStatusTone.neutral:
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