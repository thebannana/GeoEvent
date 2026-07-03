import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/profile/models/preferences_screen_state.dart';
import '../../application/preferences_controller.dart';
import '../../application/preferences_screen_controller.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(eventTaxonomyProvider);
    ref.invalidate(preferencesControllerProvider);
    ref.invalidate(preferencesScreenControllerProvider);

    await Future.wait([
      ref.read(eventTaxonomyProvider.future),
      ref.read(preferencesControllerProvider.future),
      ref.read(preferencesScreenControllerProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preferencesScreenControllerProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Affinity preferences'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        child: AppAsyncView<PreferencesScreenState>(
          value: state,
          loading: const _PreferencesLoadingView(),
          errorTitle: 'Failed to load affinity data',
          errorMessageBuilder: (_) => 'Pull to refresh or try again.',
          onRetry: () => _refreshAll(ref),
          data: (data) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _AffinityExplainerCard(),
                const SizedBox(height: 16),
                _PreferenceSection(
                  title: 'Segments',
                  icon: Icons.category_rounded,
                  items: data.segmentItems,
                  emptyMessage: 'No segment affinities have been recorded yet.',
                ),
                const SizedBox(height: 16),
                _PreferenceSection(
                  title: 'Genres',
                  icon: Icons.local_offer_rounded,
                  items: data.genreItems,
                  emptyMessage: 'No genre affinities have been recorded yet.',
                ),
                const SizedBox(height: 16),
                _PreferenceSection(
                  title: 'Subgenres',
                  icon: Icons.interests_rounded,
                  items: data.subGenreItems,
                  emptyMessage:
                      'No subgenre affinities have been recorded yet.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreferencesLoadingView extends StatelessWidget {
  const _PreferencesLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 160),
        Center(
          child: AppSpinner(size: 28, strokeWidth: 2.6),
        ),
      ],
    );
  }
}

class _AffinityExplainerCard extends StatelessWidget {
  const _AffinityExplainerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 28,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'What affinity means',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Affinity scores show how strongly your activity aligns with different event categories. '
            'They are updated automatically from interactions such as liking, bookmarking, commenting, reserving, and similar event activity.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          Text(
            'Higher scores indicate stronger interest and help personalize recommendations, search results, and discovery flows.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<PreferenceItemViewModel> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          AppEmptyState(
            icon: icon,
            title: 'Nothing here yet',
            message: emptyMessage,
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PreferenceTile(item: item),
            ),
          ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.item,
  });

  final PreferenceItemViewModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconFor(item.type),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.subtitle != null) ...[
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Score: ${item.score.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: item.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Text(
                'Updated: ${item.lastUpdated.formatDateTime(pattern: 'dd.MM.yyyy • HH:mm')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(PreferenceItemType type) {
    switch (type) {
      case PreferenceItemType.segment:
        return Icons.category_rounded;
      case PreferenceItemType.genre:
        return Icons.local_offer_rounded;
      case PreferenceItemType.subGenre:
        return Icons.interests_rounded;
    }
  }
}