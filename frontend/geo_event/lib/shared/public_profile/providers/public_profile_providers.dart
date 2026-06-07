import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/public_profile_api.dart';
import '../data/public_profile_repository.dart';

final publicProfileApiProvider = Provider<PublicProfileApi>((ref) {
  final dio = ref.watch(authorizedDioProvider);
  return PublicProfileApi(dio);
});

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) {
  final api = ref.watch(publicProfileApiProvider);
  return PublicProfileRepository(api);
});