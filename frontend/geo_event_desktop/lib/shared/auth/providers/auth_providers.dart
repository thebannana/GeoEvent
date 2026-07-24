import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../data/auth_api.dart';
import '../data/auth_local_storage.dart';
import '../data/auth_repository.dart';

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return AuthLocalStorage(ref.watch(sharedPreferencesProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    publicDio: ref.watch(baseDioProvider),
    authenticatedDio: ref.watch(authenticatedDioProvider),
  );
});

final refreshAuthApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    publicDio: ref.watch(baseDioProvider),
    authenticatedDio: ref.watch(baseDioProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    localStorage: ref.watch(authLocalStorageProvider),
  );
});