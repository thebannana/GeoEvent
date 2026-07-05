import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';

enum EventReservationsPaginationMode { none, loading, end }

class EventReservationsPaginationFooter extends StatelessWidget {
  const EventReservationsPaginationFooter({
    super.key,
    required this.mode,
  });

  final EventReservationsPaginationMode mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case EventReservationsPaginationMode.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: AppSpinner(size: 22, strokeWidth: 2),
          ),
        );
      case EventReservationsPaginationMode.end:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No more attendees to load.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      case EventReservationsPaginationMode.none:
        return const SizedBox.shrink();
    }
  }
}
