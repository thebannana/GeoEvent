import '../models/user_preference.dart';
import 'preferences_api.dart';

class PreferencesRepository {
  const PreferencesRepository(this.api);

  final PreferencesApi api;

  Future<List<UserPreference>> getPreferences() {
    return api.getPreferences();
  }

  Future<List<UserPreference>> getPreferencesForUser(int userId) {
    return api.getPreferencesForUser(userId);
  }

  Future<UserPreference> upsertPreference({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    required double score,
  }) {
    return api.upsertPreference(
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
      score: score,
    );
  }

  Future<void> deletePreference(int prefId) {
    return api.deletePreference(prefId);
  }
}