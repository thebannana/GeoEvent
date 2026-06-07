import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/events_api.dart';
import '../data/events_repository.dart';
import '../data/my_events_api.dart';
import '../data/my_events_repository.dart';

final eventsApiProvider = Provider<EventsApi>((ref) {
  return EventsApi(ref.watch(authorizedDioProvider));
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(eventsApiProvider));
});

final myEventsApiProvider = Provider<MyEventsApi>((ref) {
  return MyEventsApi(ref.watch(authorizedDioProvider));
});

final myEventsRepositoryProvider = Provider<MyEventsRepository>((ref) {
  return MyEventsRepository(ref.watch(myEventsApiProvider));
});