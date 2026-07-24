import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network.dart';
import '../data/admin_categories_api.dart';
import '../data/admin_categories_repository.dart';

final adminCategoriesApiProvider = Provider<AdminCategoriesApi>((ref) {
  final dio = ref.read(authenticatedDioProvider);
  return AdminCategoriesApi(dio);
});

final adminCategoriesRepositoryProvider =
    Provider<AdminCategoriesRepository>((ref) {
  final api = ref.read(adminCategoriesApiProvider);
  return AdminCategoriesRepository(api);
});