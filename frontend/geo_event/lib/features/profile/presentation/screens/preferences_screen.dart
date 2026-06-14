import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/profile/models/event_taxonomy_models.dart';
import '../../../../shared/profile/models/user_preference.dart';
import '../../../../shared/profile/providers/event_taxonomy_providers.dart';
import '../../application/preferences_controller.dart';

final eventTaxonomyProvider = FutureProvider<List<SegmentLookup>>((ref) async {
  return ref.read(eventTaxonomyRepositoryProvider).getSegments();
});

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesControllerProvider);
    final taxonomyAsync = ref.watch(eventTaxonomyProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Affinity Preferences'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(preferencesControllerProvider.notifier).refresh(),
            ref.refresh(eventTaxonomyProvider.future),
          ]);
        },
        child: prefsAsync.when(
          loading: () => const Center(
            child: AppSpinner(size: 28, strokeWidth: 2.6),
          ),
          error: (_, __) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _AffinityExplainerCard(),
              const SizedBox(height: 16),
              AppErrorState(
                title: 'Failed to load affinity data',
                message: 'Pull to refresh or try again.',
                onRetry: () {
                  ref.read(preferencesControllerProvider.notifier).refresh();
                  ref.invalidate(eventTaxonomyProvider);
                },
              ),
            ],
          ),
          data: (prefs) {
            return taxonomyAsync.when(
              loading: () => const Center(
                child: AppSpinner(size: 28, strokeWidth: 2.6),
              ),
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _AffinityExplainerCard(),
                  const SizedBox(height: 16),
                  AppErrorState(
                    title: 'Failed to load category names',
                    message: 'Pull to refresh or try again.',
                    onRetry: () {
                      ref.invalidate(eventTaxonomyProvider);
                    },
                  ),
                ],
              ),
              data: (segments) {
                final segmentNames = <int, String>{};
                final genreNames = <int, String>{};
                final subGenreNames = <int, String>{};

                for (final segment in segments) {
                  segmentNames[segment.segmentId] = segment.name;

                  for (final genre in segment.genres) {
                    genreNames[genre.genreId] = genre.name;

                    for (final subGenre in genre.subGenres) {
                      subGenreNames[subGenre.subGenreId] = subGenre.name;
                    }
                  }
                }

                final segmentPrefs = prefs
                    .where(
                      (p) =>
                          p.segmentId != null &&
                          p.genreId == null &&
                          p.subGenreId == null,
                    )
                    .toList()
                  ..sort(_sortByScoreThenIds);

                final genrePrefs = prefs
                    .where(
                      (p) =>
                          p.segmentId != null &&
                          p.genreId != null &&
                          p.subGenreId == null,
                    )
                    .toList()
                  ..sort(_sortByScoreThenIds);

                final subGenrePrefs = prefs
                    .where(
                      (p) =>
                          p.segmentId != null &&
                          p.genreId != null &&
                          p.subGenreId != null,
                    )
                    .toList()
                  ..sort(_sortByScoreThenIds);

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const _AffinityExplainerCard(),
                    const SizedBox(height: 16),
                    _PreferenceSection(
                      title: 'Segments',
                      icon: Icons.category_rounded,
                      preferences: segmentPrefs,
                      emptyMessage:
                          'No segment affinities have been recorded yet.',
                      segmentNames: segmentNames,
                      genreNames: genreNames,
                      subGenreNames: subGenreNames,
                    ),
                    const SizedBox(height: 16),
                    _PreferenceSection(
                      title: 'Genres',
                      icon: Icons.local_offer_rounded,
                      preferences: genrePrefs,
                      emptyMessage:
                          'No genre affinities have been recorded yet.',
                      segmentNames: segmentNames,
                      genreNames: genreNames,
                      subGenreNames: subGenreNames,
                    ),
                    const SizedBox(height: 16),
                    _PreferenceSection(
                      title: 'Subgenres',
                      icon: Icons.interests_rounded,
                      preferences: subGenrePrefs,
                      emptyMessage:
                          'No subgenre affinities have been recorded yet.',
                      segmentNames: segmentNames,
                      genreNames: genreNames,
                      subGenreNames: subGenreNames,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static int _sortByScoreThenIds(UserPreference a, UserPreference b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;

    final bySegment = (a.segmentId ?? 0).compareTo(b.segmentId ?? 0);
    if (bySegment != 0) return bySegment;

    final byGenre = (a.genreId ?? 0).compareTo(b.genreId ?? 0);
    if (byGenre != 0) return byGenre;

    return (a.subGenreId ?? 0).compareTo(b.subGenreId ?? 0);
  }
}

class _AffinityExplainerCard extends StatelessWidget {
  const _AffinityExplainerCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'What affinity means',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Affinity scores show how strongly your activity aligns with different event categories. '
            'They are updated automatically from interactions such as liking, bookmarking, commenting, reserving, and similar event activity.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Higher scores indicate stronger interest and help personalize recommendations, search results, and map visibility.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<UserPreference> preferences;
  final String emptyMessage;
  final Map<int, String> segmentNames;
  final Map<int, String> genreNames;
  final Map<int, String> subGenreNames;

  const _PreferenceSection({
    required this.title,
    required this.icon,
    required this.preferences,
    required this.emptyMessage,
    required this.segmentNames,
    required this.genreNames,
    required this.subGenreNames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (preferences.isEmpty)
          AppEmptyState(
            icon: icon,
            title: 'Nothing here yet',
            message: emptyMessage,
          )
        else
          ...preferences.map(
            (pref) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PreferenceTile(
                preference: pref,
                segmentNames: segmentNames,
                genreNames: genreNames,
                subGenreNames: subGenreNames,
              ),
            ),
          ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final UserPreference preference;
  final Map<int, String> segmentNames;
  final Map<int, String> genreNames;
  final Map<int, String> subGenreNames;

  const _PreferenceTile({
    required this.preference,
    required this.segmentNames,
    required this.genreNames,
    required this.subGenreNames,
  });

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(preference, segmentNames, genreNames, subGenreNames);
    final subtitle = _subtitleFor(
      preference,
      segmentNames,
      genreNames,
      subGenreNames,
    );

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconFor(preference),
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Score: ${preference.score.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (preference.score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Text(
                'Updated: ${_formatDate(preference.lastUpdated)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(
    UserPreference pref,
    Map<int, String> segmentNames,
    Map<int, String> genreNames,
    Map<int, String> subGenreNames,
  ) {
    if (pref.subGenreId != null) {
      return subGenreNames[pref.subGenreId!] ?? 'Subgenre #${pref.subGenreId}';
    }
    if (pref.genreId != null) {
      return genreNames[pref.genreId!] ?? 'Genre #${pref.genreId}';
    }
    if (pref.segmentId != null) {
      return segmentNames[pref.segmentId!] ?? 'Segment #${pref.segmentId}';
    }
    return 'Preference #${pref.prefId}';
  }

  static String? _subtitleFor(
    UserPreference pref,
    Map<int, String> segmentNames,
    Map<int, String> genreNames,
    Map<int, String> subGenreNames,
  ) {
    if (pref.subGenreId != null) {
      final segment = pref.segmentId != null
          ? (segmentNames[pref.segmentId!] ?? 'Segment #${pref.segmentId}')
          : null;
      final genre = pref.genreId != null
          ? (genreNames[pref.genreId!] ?? 'Genre #${pref.genreId}')
          : null;
      return [segment, genre].whereType<String>().join(' • ');
    }

    if (pref.genreId != null) {
      return pref.segmentId != null
          ? (segmentNames[pref.segmentId!] ?? 'Segment #${pref.segmentId}')
          : null;
    }

    return null;
  }

  static IconData _iconFor(UserPreference pref) {
    if (pref.subGenreId != null) return Icons.interests_rounded;
    if (pref.genreId != null) return Icons.local_offer_rounded;
    return Icons.category_rounded;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year • $hour:$minute';
  }
}