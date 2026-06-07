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

  Future<void> upsert({
    int? segmentId,
    int? genreId,
    required double score,
  }) async {
    final repository = ref.read(preferencesRepositoryProvider);
    final updated = await repository.upsertPreference(
      segmentId: segmentId,
      genreId: genreId,
      score: score,
    );

    state.whenData((list) {
      final index = list.indexWhere((p) => p.prefId == updated.prefId);

      if (index >= 0) {
        final next = [...list];
        next[index] = updated;
        state = AsyncData(_sort(next));
      } else {
        state = AsyncData(_sort([...list, updated]));
      }
    });
  }

  Future<void> delete(int prefId) async {
    await ref.read(preferencesRepositoryProvider).deletePreference(prefId);

    state.whenData((list) {
      state = AsyncData(
        _sort(list.where((p) => p.prefId != prefId).toList()),
      );
    });
  }

  List<UserPreference> _sort(List<UserPreference> items) {
    final next = [...items];
    next.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      final aType = a.segmentId != null ? 0 : 1;
      final bType = b.segmentId != null ? 0 : 1;
      if (aType != bType) return aType.compareTo(bType);

      final aId = a.segmentId ?? a.genreId ?? 0;
      final bId = b.segmentId ?? b.genreId ?? 0;
      return aId.compareTo(bId);
    });
    return next;
  }
}