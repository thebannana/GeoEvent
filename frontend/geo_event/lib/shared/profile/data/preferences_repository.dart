import '../models/user_preference.dart';
import 'preferences_api.dart';

class PreferencesRepository {
  final PreferencesApi _api;

  PreferencesRepository(this._api);

  Future<List<UserPreference>> getPreferences() => _api.getPreferences();
}