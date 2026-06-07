import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/tickets_api.dart';
import '../data/tickets_repository.dart';

final ticketsApiProvider = Provider<TicketsApi>((ref) {
  final dio = ref.watch(authorizedDioProvider);
  return TicketsApi(dio);
});

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  final api = ref.watch(ticketsApiProvider);
  return TicketsRepository(api);
});