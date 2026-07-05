import 'package:flutter/material.dart';

import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/reservations/models/reservation_status.dart';

class EventReservationsStatusFilterBar extends StatelessWidget {
  const EventReservationsStatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
  });

  final ReservationStatus? selectedStatus;
  final ValueChanged<ReservationStatus?> onSelected;

  static const _filters = <({String label, ReservationStatus? value})>[
    (label: 'Confirmed', value: ReservationStatus.confirmed),
    (label: 'Pending', value: ReservationStatus.pending),
    (label: 'Cancelled', value: ReservationStatus.cancelled),
    (label: 'Refunded', value: ReservationStatus.refunded),
    (label: 'All', value: null),
  ];

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in _filters)
            AppChip(
              label: filter.label,
              selected: selectedStatus == filter.value,
              compact: true,
              onTap: () => onSelected(filter.value),
            ),
        ],
      ),
    );
  }
}
