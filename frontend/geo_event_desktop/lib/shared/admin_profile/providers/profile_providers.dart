import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(authenticatedDioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(profileApiProvider));
});
