import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/bookmark_api.dart';
import '../data/bookmark_repository.dart';

final bookmarkApiProvider = Provider<BookmarkApi>((ref) {
  return BookmarkApi(ref.watch(authorizedDioProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(bookmarkApiProvider));
});