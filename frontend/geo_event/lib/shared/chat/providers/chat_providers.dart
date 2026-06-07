import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/network/api_client.dart';

import '../data/chat_api.dart';
import '../data/chat_repository.dart';

final messagesApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(authorizedDioProvider));
});

final messagesRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(messagesApiProvider));
});