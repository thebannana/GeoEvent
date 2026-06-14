import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/profile/models/user_preference.dart';
import '../../../shared/profile/providers/profile_providers.dart';

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, List<UserPreference>>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<List<UserPreference>> {
  @override
  Future<List<UserPreference>> build() async {
    final items = await ref.read(preferencesRepositoryProvider).getPreferences();
    return _sort(items);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items =
          await ref.read(preferencesRepositoryProvider).getPreferences();
      return _sort(items);
    });
  }

  List<UserPreference> _sort(List<UserPreference> items) {
    final next = [...items];
    next.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      final aDepth = _depth(a);
      final bDepth = _depth(b);
      if (aDepth != bDepth) return aDepth.compareTo(bDepth);

      final bySegment = (a.segmentId ?? 0).compareTo(b.segmentId ?? 0);
      if (bySegment != 0) return bySegment;

      final byGenre = (a.genreId ?? 0).compareTo(b.genreId ?? 0);
      if (byGenre != 0) return byGenre;

      return (a.subGenreId ?? 0).compareTo(b.subGenreId ?? 0);
    });
    return next;
  }

  int _depth(UserPreference pref) {
    if (pref.subGenreId != null) return 2;
    if (pref.genreId != null) return 1;
    return 0;
  }
}