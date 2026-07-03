import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/events/models/create_event_models.dart';
import '../../../shared/events/providers/event_providers.dart';
import '../data/reservations_api.dart';
import '../data/reservations_repository.dart';

final reservationsApiProvider = Provider<ReservationsApi>((ref) {
  return ReservationsApi(ref.watch(authorizedDioProvider));
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(reservationsApiProvider));
});

final reservationEventProvider =
    FutureProvider.family<EventItem, int>((ref, eventId) async {
  return ref.read(eventsRepositoryProvider).getEventById(eventId);
});