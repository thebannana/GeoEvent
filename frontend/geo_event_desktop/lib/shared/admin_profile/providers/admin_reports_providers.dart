import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network.dart';
import '../data/admin_reports_api.dart';
import '../data/admin_reports_repository.dart';

final adminReportsApiProvider = Provider<AdminReportsApi>((ref) {
  return AdminReportsApi(ref.watch(authenticatedDioProvider));
});

final adminReportsRepositoryProvider = Provider<AdminReportsRepository>((ref) {
  return AdminReportsRepository(ref.watch(adminReportsApiProvider));
});