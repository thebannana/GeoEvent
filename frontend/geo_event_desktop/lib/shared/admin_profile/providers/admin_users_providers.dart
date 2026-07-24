import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network.dart';
import '../data/admin_users_api.dart';
import '../data/admin_users_repository.dart';

final adminUsersApiProvider = Provider<AdminUsersApi>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return AdminUsersApi(dio);
});

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  final api = ref.read(adminUsersApiProvider);
  return AdminUsersRepository(api);
});