import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../shared/profile/data/preferences_api.dart';
import '../../../shared/profile/data/preferences_repository.dart';
import '../../../shared/profile/models/user_preference.dart';

final preferencesApiProvider = Provider<PreferencesApi>((ref) {
  return PreferencesApi(ref.watch(authorizedDioProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(preferencesApiProvider));
});

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, List<UserPreference>>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<List<UserPreference>> {
  PreferencesRepository get _repository =>
      ref.read(preferencesRepositoryProvider);

  @override
  Future<List<UserPreference>> build() async {
    return _repository.getPreferences();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getPreferences);
  }

  Future<void> upsert({int? segmentId, int? genreId, required double score}) async {
    final updated = await _repository.upsertPreference(
      segmentId: segmentId,
      genreId: genreId,
      score: score,
    );
    state.whenData((list) {
      final idx = list.indexWhere((p) => p.prefId == updated.prefId);
      if (idx >= 0) {
        final newList = [...list];
        newList[idx] = updated;
        state = AsyncData(newList);
      } else {
        state = AsyncData([...list, updated]);
      }
    });
  }

  Future<void> delete(int prefId) async {
    await _repository.deletePreference(prefId);
    state.whenData((list) {
      state = AsyncData(list.where((p) => p.prefId != prefId).toList());
    });
  }
}