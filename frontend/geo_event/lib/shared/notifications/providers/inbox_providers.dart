import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/notification_api.dart';
import '../data/notification_repository.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(
    authorizedDio: ref.watch(authorizedDioProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    api: ref.watch(notificationApiProvider),
  );
});