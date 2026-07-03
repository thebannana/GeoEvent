import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/tickets_api.dart';
import '../data/tickets_repository.dart';
import '../models/ticket_models.dart';

final ticketsApiProvider = Provider<TicketsApi>((ref) {
  return TicketsApi(ref.watch(authorizedDioProvider));
});

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return TicketsRepository(ref.watch(ticketsApiProvider));
});

final eventTicketsProvider =
    FutureProvider.autoDispose.family<List<EventTicketItem>, int>((
      ref,
      eventId,
    ) async {
      final repo = ref.watch(ticketsRepositoryProvider);
      return repo.getEventTickets(eventId);
    });