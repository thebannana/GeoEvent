import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/profile/data/preferences_repository.dart';
import '../../../shared/profile/models/user_preference.dart';
import '../../../shared/profile/providers/profile_providers.dart';

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, List<UserPreference>>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<List<UserPreference>> {
  PreferencesRepository get _repository =>
      ref.read(preferencesRepositoryProvider);

  @override
  Future<List<UserPreference>> build() async {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return const <UserPreference>[];
    }

    return _load();
  }

  Future<void> refresh() async {
    final authState = ref.read(authStateProvider);

    if (!authState.isAuthenticated) {
      state = const AsyncData(<UserPreference>[]);
      return;
    }

    final previous = state.valueOrNull;
    if (previous != null) {
      state =
          AsyncLoading<List<UserPreference>>().copyWithPrevious(AsyncData(previous));
    } else {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(_load);
  }

  Future<bool> upsertPreference({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    required double score,
  }) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      state = const AsyncData(<UserPreference>[]);
      return false;
    }

    try {
      await _repository.upsertPreference(
        segmentId: segmentId,
        genreId: genreId,
        subGenreId: subGenreId,
        score: score,
      );

      state = await AsyncValue.guard(_load);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> deletePreference(int prefId) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      state = const AsyncData(<UserPreference>[]);
      return false;
    }

    try {
      await _repository.deletePreference(prefId);
      state = await AsyncValue.guard(_load);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<List<UserPreference>> _load() async {
    final items = await _repository.getPreferences();
    return _sort(items);
  }

  List<UserPreference> _sort(List<UserPreference> items) {
    final sorted = [...items];

    sorted.sort((a, b) {
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

    return sorted;
  }

  int _depth(UserPreference preference) {
    if (preference.subGenreId != null) return 2;
    if (preference.genreId != null) return 1;
    return 0;
  }
}