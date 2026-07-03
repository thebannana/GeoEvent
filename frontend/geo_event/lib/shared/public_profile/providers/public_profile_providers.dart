import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/public_profile_api.dart';
import '../data/public_profile_repository.dart';

final publicProfileApiProvider = Provider<PublicProfileApi>((ref) {
  return PublicProfileApi(ref.watch(authorizedDioProvider));
});

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) {
  return PublicProfileRepository(ref.watch(publicProfileApiProvider));
});