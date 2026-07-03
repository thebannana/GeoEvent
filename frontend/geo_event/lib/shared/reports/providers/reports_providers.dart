import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/reports_api.dart';
import '../data/reports_repository.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(ref.watch(authorizedDioProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(reportsApiProvider));
});