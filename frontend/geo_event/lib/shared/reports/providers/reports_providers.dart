import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/reports_api.dart';
import '../data/reports_repository.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  final dio = ref.watch(authorizedDioProvider);
  return ReportsApi(dio);
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final api = ref.watch(reportsApiProvider);
  return ReportsRepository(api);
});