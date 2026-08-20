import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/profile/data/preferences_repository.dart';
import '../../../shared/profile/models/preferences_list_state.dart';
import '../../../shared/profile/models/preferences_query.dart';
import '../../../shared/profile/models/user_preference.dart';
import '../../../shared/profile/providers/profile_providers.dart';

final preferencesControllerProvider = AsyncNotifierProvider<
    PreferencesController, PreferencesListState>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<PreferencesListState> {
  PreferencesRepository get _repository =>
      ref.read(preferencesRepositoryProvider);

  @override
  Future<PreferencesListState> build() async {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return PreferencesListState.initial();
    }

    return _load(const PreferencesQuery());
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? PreferencesListState.initial();
    state = AsyncLoading<PreferencesListState>().copyWithPrevious(
      AsyncData(current),
    );

    state = await AsyncValue.guard(() => _load(current.query));
  }

  Future<void> applyFilters({
  String? type,
  double? minScore,
  double? maxScore,
  bool clearType = false,
  bool clearMinScore = false,
  bool clearMaxScore = false,
}) async {
  final currentState = state.valueOrNull ?? PreferencesListState.initial();

  final query = currentState.query.copyWith(
    page: 1,
    type: type,
    minScore: minScore,
    maxScore: maxScore,
    clearType: clearType,
    clearMinScore: clearMinScore,
    clearMaxScore: clearMaxScore,
  );

  await _load(query);
}

  Future<void> goToPage(int page) async {
    final current = state.valueOrNull ?? PreferencesListState.initial();
    final nextQuery = current.query.copyWith(page: page);

    state = AsyncLoading<PreferencesListState>().copyWithPrevious(
      AsyncData(current),
    );

    state = await AsyncValue.guard(() => _load(nextQuery));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.result.hasNextPage) return;
    await goToPage(current.result.page + 1);
  }

  Future<void> previousPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.result.hasPreviousPage) return;
    await goToPage(current.result.page - 1);
  }

  Future<List<UserPreference>> currentItems() async {
    final current = state.valueOrNull;
    if (current != null) return current.result.items;
    return const <UserPreference>[];
  }

  Future<PreferencesListState> _load(PreferencesQuery query) async {
    final authState = ref.read(authStateProvider);

    if (!authState.isAuthenticated) {
      return PreferencesListState.initial();
    }

    final result = await _repository.getPreferences(query: query);

    return PreferencesListState(
      query: query,
      result: result,
    );
  }
}