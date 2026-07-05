import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/event_reservations/application/event_reservations_controller.dart';
import '../data/organizer_reservations_repository.dart';
import '../models/event_reservations_state.dart';

final eventReservationsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventReservationsController, EventReservationsState, int>(
  (ref, eventId) {
    return EventReservationsController(
      eventId: eventId,
      repository: ref.watch(organizerReservationsRepositoryProvider),
    );
  },
);