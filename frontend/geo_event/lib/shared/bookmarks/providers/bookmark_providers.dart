import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/network/api_client.dart';

import '../application/bookmark_controller.dart';
import '../data/bookmark_api.dart';
import '../data/bookmark_repository.dart';
import '../models/bookmark.dart';

final bookmarkApiProvider = Provider<BookmarkApi>((ref) {
  return BookmarkApi(ref.watch(authorizedDioProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(bookmarkApiProvider));
});

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksController, List<Bookmark>>(
  BookmarksController.new,
);