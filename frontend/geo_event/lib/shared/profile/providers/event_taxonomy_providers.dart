import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/network/api_client.dart';

import '../data/event_taxonomy_api.dart';
import '../data/event_taxonomy_repository.dart';

final eventTaxonomyApiProvider = Provider<EventTaxonomyApi>((ref) {
  return EventTaxonomyApi(ref.watch(authorizedDioProvider));
});

final eventTaxonomyRepositoryProvider = Provider<EventTaxonomyRepository>((ref) {
  return EventTaxonomyRepository(ref.watch(eventTaxonomyApiProvider));
});