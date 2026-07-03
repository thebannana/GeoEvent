import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../data/auth_local_storage.dart';
import '../data/auth_repository.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return AuthLocalStorage(ref.watch(flutterSecureStorageProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    publicDio: ref.watch(baseDioProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    localStorage: ref.watch(authLocalStorageProvider),
  );
});