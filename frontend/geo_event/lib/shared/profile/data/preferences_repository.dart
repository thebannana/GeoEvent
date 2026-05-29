import '../models/user_preference.dart';
import 'preferences_api.dart';

class PreferencesRepository {
  final PreferencesApi _api;
  PreferencesRepository(this._api);

  Future<List<UserPreference>> getPreferences() => _api.getPreferences();

  Future<UserPreference> upsertPreference({
    int? segmentId,
    int? genreId,
    required double score,
  }) =>
      _api.upsertPreference(
          segmentId: segmentId, genreId: genreId, score: score);

  Future<void> deletePreference(int prefId) => _api.deletePreference(prefId);
}