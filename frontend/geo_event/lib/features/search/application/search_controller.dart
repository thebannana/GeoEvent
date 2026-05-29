import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/data/events_api.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/profile/models/user_preference.dart';
import '../../profile/application/preferences_controller.dart';
import '../domain/filter_selection.dart';
import '../domain/sort_option.dart';
import 'search_state.dart';

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController(ref);
});

class SearchController extends StateNotifier<SearchState> {
  SearchController(this.ref) : super(const SearchState());

  final Ref ref;

  Map<int, double> _segmentWeights(List<UserPreference> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final segmentId = pref.segmentId;
      if (segmentId != null) {
        map[segmentId] = (map[segmentId] ?? 0) + pref.score;
      }
    }

    return map;
  }

  Map<int, double> _genreWeights(List<UserPreference> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final genreId = pref.genreId;
      if (genreId != null) {
        map[genreId] = (map[genreId] ?? 0) + pref.score;
      }
    }

    return map;
  }

  double _preferenceScore(
    EventItem item,
    Map<int, double> segmentWeights,
    Map<int, double> genreWeights,
  ) {
    var score = 0.0;

    if (item.segmentId != null) {
      score += (segmentWeights[item.segmentId!] ?? 0) * 30;
    }

    if (item.genreId != null) {
      score += (genreWeights[item.genreId!] ?? 0) * 22;
    }

    if (item.isFeatured) {
      score += 6;
    }

    return score;
  }

  List<UserPreference> _preferences() {
    return ref.read(preferencesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => <UserPreference>[],
        );
  }

  Future<void> loadInitial({bool force = false}) async {
    if (state.loadedInitial && !force) return;

    state = state.copyWith(loading: true, clearError: true);

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            page: 1,
            pageSize: 20,
            sortBy: state.sort.sortBy,
            sortDescending: state.sort.sortDescending,
            segmentId: state.filter.segmentId,
            genreId: state.filter.genreId,
            subGenreId: state.filter.subGenreId,
          );

      final preferences = _preferences();
      final segmentWeights = _segmentWeights(preferences);
      final genreWeights = _genreWeights(preferences);

      final ranked = [...items]..sort((a, b) {
          final aScore =
              _preferenceScore(a, segmentWeights, genreWeights) +
                  (a.likesCount / 20) +
                  (a.viewCount / 200);

          final bScore =
              _preferenceScore(b, segmentWeights, genreWeights) +
                  (b.likesCount / 20) +
                  (b.viewCount / 200);

          return bScore.compareTo(aScore);
        });

      state = state.copyWith(
        results: ranked,
        loading: false,
        loadedInitial: true,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    state = state.copyWith(query: query);

    if (trimmed.isEmpty) {
      await loadInitial(force: true);
      return;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            searchTerm: trimmed,
            page: 1,
            pageSize: 20,
            sortBy: state.sort.sortBy,
            sortDescending: state.sort.sortDescending,
            segmentId: state.filter.segmentId,
            genreId: state.filter.genreId,
            subGenreId: state.filter.subGenreId,
          );

      final preferences = _preferences();
      final segmentWeights = _segmentWeights(preferences);
      final genreWeights = _genreWeights(preferences);
      final q = trimmed.toLowerCase();

      double score(EventItem item) {
        var total = 0.0;

        final title = item.title.toLowerCase();
        final description = item.description.toLowerCase();
        final segment = (item.segmentName ?? '').toLowerCase();
        final genre = (item.genreName ?? '').toLowerCase();
        final subGenre = (item.subGenreName ?? '').toLowerCase();
        final tags = (item.tags ?? '').toLowerCase();
        final promoter = (item.promoterName ?? '').toLowerCase();

        if (title.contains(q)) total += 90;
        if (description.contains(q)) total += 30;
        if (segment.contains(q)) total += 28;
        if (genre.contains(q)) total += 24;
        if (subGenre.contains(q)) total += 20;
        if (tags.contains(q)) total += 18;
        if (promoter.contains(q)) total += 14;

        total += _preferenceScore(item, segmentWeights, genreWeights);
        total += item.likesCount / 20;
        total += item.viewCount / 200;

        return total;
      }

      final ranked = [...items]..sort((a, b) => score(b).compareTo(score(a)));

      state = state.copyWith(
        results: ranked,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> clearQuery() async {
    state = state.copyWith(query: '');
    await loadInitial(force: true);
  }

  Future<void> applySort(SortOption option) async {
    state = state.copyWith(sort: option);

    if (state.query.trim().isEmpty) {
      await loadInitial(force: true);
    } else {
      await search(state.query);
    }
  }

  Future<void> applyFilter(FilterSelection filter) async {
    state = state.copyWith(filter: filter);

    if (state.query.trim().isEmpty) {
      await loadInitial(force: true);
    } else {
      await search(state.query);
    }
  }
}