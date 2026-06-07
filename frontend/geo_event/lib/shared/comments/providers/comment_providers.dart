import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/comments_api.dart';
import '../data/comments_repository.dart';

final commentsApiProvider = Provider<CommentsApi>((ref) {
  return CommentsApi(ref.watch(authorizedDioProvider));
});

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository(ref.watch(commentsApiProvider));
});