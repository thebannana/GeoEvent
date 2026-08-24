import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _minScoreController = TextEditingController();
  final _maxScoreController = TextEditingController();

  String? _selectedType;

@override
void initState() {
  super.initState();

  Future.microtask(() async {
    ref.invalidate(eventTaxonomyProvider);
    ref.invalidate(preferencesScreenControllerProvider);

    await ref
        .read(preferencesControllerProvider.notifier)
        .refresh();

    if (!mounted) return;

    await Future.wait([
      ref.read(eventTaxonomyProvider.future),
      ref.read(preferencesScreenControllerProvider.future),
    ]);
  });
}

  @override
  void dispose() {
    _minScoreController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

Future<void> _refreshAll() async {
  ref.invalidate(eventTaxonomyProvider);
  ref.invalidate(preferencesScreenControllerProvider);

  await ref
      .read(preferencesControllerProvider.notifier)
      .refresh();

  if (!mounted) return;

  await Future.wait([
    ref.read(eventTaxonomyProvider.future),
    ref.read(preferencesScreenControllerProvider.future),
  ]);
}

  Future<void> _applyFilters() async {
    final minText = _minScoreController.text.trim();
    final maxText = _maxScoreController.text.trim();

    final minScore = double.tryParse(minText);
    final maxScore = double.tryParse(maxText);

    if (minText.isNotEmpty && minScore == null) {
      _showMessage('Enter a valid minimum score.');
      return;
    }

    if (maxText.isNotEmpty && maxScore == null) {
      _showMessage('Enter a valid maximum score.');
      return;
    }

    if (minScore != null && maxScore != null && minScore > maxScore) {
      _showMessage('Minimum score cannot be greater than maximum score.');
      return;
    }

    await ref.read(preferencesControllerProvider.notifier).applyFilters(
          type: _selectedType,
          minScore: minScore,
          maxScore: maxScore,
          clearType: _selectedType == null,
          clearMinScore: minText.isEmpty,
          clearMaxScore: maxText.isEmpty,
        );

    ref.invalidate(preferencesScreenControllerProvider);
  }

  Future<void> _clearFilters() async {
    _minScoreController.clear();
    _maxScoreController.clear();

    setState(() {
      _selectedType = null;
    });

    await ref.read(preferencesControllerProvider.notifier).applyFilters(
          clearType: true,
          clearMinScore: true,
          clearMaxScore: true,
        );

    ref.invalidate(preferencesScreenControllerProvider);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesScreenControllerProvider);
    final listState = ref.watch(preferencesControllerProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Affinity preferences'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: AppAsyncView<PreferencesScreenState>(
          value: state,
          loading: const _PreferencesLoadingView(),
          errorTitle: 'Failed to load affinity data',
          errorMessageBuilder: (_) => 'Pull to refresh or try again.',
          onRetry: _refreshAll,
          data: (data) {
            final isPageLoading = listState.isLoading && listState.hasValue;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _AffinityExplainerCard(),
                const SizedBox(height: 16),
                _PreferencesFilters(
                  minScoreController: _minScoreController,
                  maxScoreController: _maxScoreController,
                  selectedType: _selectedType,
                  onTypeChanged: (value) =>
                      setState(() => _selectedType = value),
                  onApply: _applyFilters,
                  onClear: _clearFilters,
                ),
                const SizedBox(height: 16),
                if (isPageLoading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                if (data.isEmpty)
                  const AppEmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Nothing here yet',
                    message:
                        'No affinity preferences found for the current filters.',
                  )
                else ...[
                  _PreferenceSection(
                    title: 'Segments',
                    icon: Icons.category_rounded,
                    items: data.segmentItems,
                    emptyMessage: 'No segment affinities on this page.',
                  ),
                  const SizedBox(height: 16),
                  _PreferenceSection(
                    title: 'Genres',
                    icon: Icons.local_offer_rounded,
                    items: data.genreItems,
                    emptyMessage: 'No genre affinities on this page.',
                  ),
                  const SizedBox(height: 16),
                  _PreferenceSection(
                    title: 'Subgenres',
                    icon: Icons.interests_rounded,
                    items: data.subGenreItems,
                    emptyMessage: 'No subgenre affinities on this page.',
                  ),
                ],
                const SizedBox(height: 20),
                _PaginationBar(
                  page: data.page,
                  totalPages: data.totalPages,
                  totalCount: data.totalCount,
                  hasNextPage: data.hasNextPage,
                  hasPreviousPage: data.hasPreviousPage,
                  onPrevious: () async {
                    await ref
                        .read(preferencesControllerProvider.notifier)
                        .previousPage();

                    ref.invalidate(preferencesScreenControllerProvider);
                  },
                  onNext: () async {
                    await ref
                        .read(preferencesControllerProvider.notifier)
                        .nextPage();

                    ref.invalidate(preferencesScreenControllerProvider);
                  },
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

class _PreferencesFilters extends StatelessWidget {
  const _PreferencesFilters({
    required this.minScoreController,
    required this.maxScoreController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController minScoreController;
  final TextEditingController maxScoreController;
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final decimalInputFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d{0,2}$'),
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'segment',
                child: Text('Segment'),
              ),
              DropdownMenuItem<String>(
                value: 'genre',
                child: Text('Genre'),
              ),
              DropdownMenuItem<String>(
                value: 'subgenre',
                child: Text('Subgenre'),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minScoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalInputFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Min score',
                    hintText: '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxScoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalInputFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Max score',
                    hintText: '100',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Page $page of $totalPages • $totalCount total items'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: hasPreviousPage ? onPrevious : null,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: hasNextPage ? onNext : null,
                  child: const Text('Next'),
                ),
              ),
            ],
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