import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network.dart';
import '../data/admin_events_api.dart';
import '../data/admin_events_repository.dart';

final adminEventsApiProvider = Provider<AdminEventsApi>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return AdminEventsApi(dio);
});

final adminEventsRepositoryProvider = Provider<AdminEventsRepository>((ref) {
  final api = ref.read(adminEventsApiProvider);
  return AdminEventsRepository(api);
});