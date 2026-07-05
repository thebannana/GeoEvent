import '../../../shared/profile/models/paged_result.dart';
import '../../../shared/profile/models/preferences_query.dart';
import '../../../shared/profile/models/user_preference.dart';

class PreferencesListState {
  const PreferencesListState({
    required this.query,
    required this.result,
  });

  final PreferencesQuery query;
  final PagedResult<UserPreference> result;

  PreferencesListState copyWith({
    PreferencesQuery? query,
    PagedResult<UserPreference>? result,
  }) {
    return PreferencesListState(
      query: query ?? this.query,
      result: result ?? this.result,
    );
  }

  factory PreferencesListState.initial() {
    return PreferencesListState(
      query: const PreferencesQuery(),
      result: PagedResult<UserPreference>.empty(),
    );
  }
}