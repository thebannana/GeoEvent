import '../models/paged_result.dart';
import '../models/preferences_query.dart';
import '../models/user_preference.dart';
import 'preferences_api.dart';

class PreferencesRepository {
  const PreferencesRepository(this.api);

  final PreferencesApi api;

  Future<PagedResult<UserPreference>> getPreferences({
    PreferencesQuery query = const PreferencesQuery(),
  }) {
    return api.getPreferences(query: query);
  }

  Future<PagedResult<UserPreference>> getPreferencesForUser(
    int userId, {
    PreferencesQuery query = const PreferencesQuery(),
  }) {
    return api.getPreferencesForUser(userId, query: query);
  }
}