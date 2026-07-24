import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network.dart';
import '../data/admin_refunds_api.dart';
import '../data/admin_refunds_repository.dart';

final adminRefundsApiProvider = Provider<AdminRefundsApi>((ref) {
  return AdminRefundsApi(ref.watch(authenticatedDioProvider));
});

final adminRefundsRepositoryProvider = Provider<AdminRefundsRepository>((ref) {
  return AdminRefundsRepository(ref.watch(adminRefundsApiProvider));
});