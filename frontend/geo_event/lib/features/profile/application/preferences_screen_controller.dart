import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/profile/models/event_taxonomy_models.dart';
import '../../../shared/profile/models/preferences_screen_state.dart';
import '../../../shared/profile/models/user_preference.dart';
import '../../../shared/profile/providers/event_taxonomy_providers.dart';
import '../../profile/application/preferences_controller.dart';

final eventTaxonomyProvider =
    FutureProvider<List<SegmentLookup>>((ref) async {
  return ref.read(eventTaxonomyRepositoryProvider).getSegments();
});

final preferencesScreenControllerProvider =
    FutureProvider<PreferencesScreenState>((ref) async {
  final preferences = await ref.watch(preferencesControllerProvider.future);
  final segments = await ref.watch(eventTaxonomyProvider.future);

  return _PreferencesScreenMapper.map(
    preferences: preferences,
    segments: segments,
  );
});

class _PreferencesScreenMapper {
  static PreferencesScreenState map({
    required List<UserPreference> preferences,
    required List<SegmentLookup> segments,
  }) {
    final genreById = <int, GenreLookup>{};
    final subGenreById = <int, SubGenreLookup>{};
    final segmentById = <int, SegmentLookup>{};

    for (final segment in segments) {
      segmentById[segment.segmentId] = segment;

      for (final genre in segment.genres) {
        genreById[genre.genreId] = genre;

        for (final subGenre in genre.subGenres) {
          subGenreById[subGenre.subGenreId] = subGenre;
        }
      }
    }

    final segmentItems = <PreferenceItemViewModel>[];
    final genreItems = <PreferenceItemViewModel>[];
    final subGenreItems = <PreferenceItemViewModel>[];

    final maxScore = preferences.isEmpty
        ? 1.0
        : preferences
            .map((e) => e.score)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    for (final preference in preferences) {
      if (preference.subGenreId != null) {
        final subGenre = subGenreById[preference.subGenreId!];
        final genre = subGenre?.genreId != null
            ? genreById[subGenre!.genreId!]
            : null;

        subGenreItems.add(
          PreferenceItemViewModel(
            prefId: preference.prefId,
            title: subGenre?.name ?? 'Subgenre #${preference.subGenreId}',
            subtitle: genre?.name,
            score: preference.score,
            progress: _normalizeProgress(preference.score, maxScore),
            lastUpdated: preference.lastUpdated,
            type: PreferenceItemType.subGenre,
          ),
        );
        continue;
      }

      if (preference.genreId != null) {
        final genre = genreById[preference.genreId!];
        final segment = genre?.segmentId != null
            ? segmentById[genre!.segmentId!]
            : null;

        genreItems.add(
          PreferenceItemViewModel(
            prefId: preference.prefId,
            title: genre?.name ?? 'Genre #${preference.genreId}',
            subtitle: segment?.name,
            score: preference.score,
            progress: _normalizeProgress(preference.score, maxScore),
            lastUpdated: preference.lastUpdated,
            type: PreferenceItemType.genre,
          ),
        );
        continue;
      }

      if (preference.segmentId != null) {
        final segment = segmentById[preference.segmentId!];

        segmentItems.add(
          PreferenceItemViewModel(
            prefId: preference.prefId,
            title: segment?.name ?? 'Segment #${preference.segmentId}',
            subtitle: null,
            score: preference.score,
            progress: _normalizeProgress(preference.score, maxScore),
            lastUpdated: preference.lastUpdated,
            type: PreferenceItemType.segment,
          ),
        );
      }
    }

    return PreferencesScreenState(
      segmentItems: segmentItems,
      genreItems: genreItems,
      subGenreItems: subGenreItems,
    );
  }

  static double _normalizeProgress(double score, double maxScore) {
    if (maxScore <= 0) return 0;
    final value = score / maxScore;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}