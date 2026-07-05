import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../application/search_controller.dart';
import '../../domain/filter_selection.dart';
import '../../domain/sort_option.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_sort_bottom_sheet.dart';

class SearchSheet extends ConsumerStatefulWidget {
  final VoidCallback? onCloseSheet;

  const SearchSheet({
    super.key,
    this.onCloseSheet,
  });

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchControllerProvider.notifier).loadInitial();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  void _closeParentSearchSheet() {
    widget.onCloseSheet?.call();
  }

  Future<void> _reloadCurrentResults() async {
    await ref.read(searchControllerProvider.notifier).loadInitial(force: true);
  }

  Future<void> _openDirections(EventItem item) async {
    final activeNavigation = ref.read(activeNavigationProvider);

    if (activeNavigation?.eventId == item.eventId) {
      await Navigator.of(context).maybePop();
      _closeParentSearchSheet();
      return;
    }

    ref.read(pendingDirectionsProvider.notifier).state = EventDirectionsRequest(
      eventId: item.eventId,
      latitude: item.latitude,
      longitude: item.longitude,
      title: item.title,
    );

    await Navigator.of(context).maybePop();
    _closeParentSearchSheet();
  }

  void _onQueryChanged(String value) {
    if (mounted) {
      setState(() {});
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchControllerProvider.notifier).search(value);
    });
  }

  Future<T?> _showSheetSafeDialog<T>({
    required Widget child,
  }) async {
    if (_isDialogOpen || !mounted) return null;

    _isDialogOpen = true;
    FocusScope.of(context).unfocus();

    try {
      await Future<void>.delayed(Duration.zero);

      if (!mounted) return null;

      return await showDialog<T>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.78,
                maxWidth: 560,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Material(
                  color: Theme.of(dialogContext).colorScheme.surface,
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _isDialogOpen = false;
    }
  }

  Future<void> _openSortSheet() async {
    final currentState = ref.read(searchControllerProvider);

    final selected = await _showSheetSafeDialog<SortOption>(
      child: SearchSortBottomSheet(
        selected: currentState.sort,
      ),
    );

    if (selected == null || !mounted) return;
    await ref.read(searchControllerProvider.notifier).applySort(selected);
  }

  Future<void> _openFilterSheet() async {
    try {
      final currentState = ref.read(searchControllerProvider);
      final segments = await ref.read(eventsApiProvider).getSegments();

      if (!mounted) return;

      final result = await _showSheetSafeDialog<FilterSelection>(
        child: SearchFilterBottomSheet(
          initialSegmentId: currentState.filter.segmentId,
          initialGenreId: currentState.filter.genreId,
          initialSubGenreId: currentState.filter.subGenreId,
          segments: segments,
        ),
      );

      if (result == null || !mounted) return;
      await ref.read(searchControllerProvider.notifier).applyFilter(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget _buildFooter({
    required bool loadingMore,
    required bool hasMore,
    required int loadedCount,
    required int totalCount,
  }) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: AppSpinner(size: 22, strokeWidth: 2),
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(searchControllerProvider.notifier).loadMore(),
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(
              totalCount > 0
                  ? 'Load more ($loadedCount/$totalCount)'
                  : 'Load more',
            ),
          ),
        ),
      );
    }

    if (loadedCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Showing all $loadedCount events',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(searchControllerProvider);
    final query = _textController.text.trim();

    if (state.loading && state.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 28),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppLoadingIndicator(
              title: 'Loading events',
              message: 'Please wait while we prepare your results.',
              centered: false,
            ),
          ),
          SizedBox(height: 24),
        ],
      );
    }

    if (state.error != null && state.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          AppErrorState(
            message: state.error!,
            onRetry: _reloadCurrentResults,
          ),
        ],
      );
    }

    if (query.isEmpty && state.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: const [
          AppEmptyState(
            title: 'No events available',
            message: 'There are no events available right now.',
          ),
        ],
      );
    }

    if (query.isNotEmpty && state.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: const [
          AppEmptyState(
            title: 'No events found',
            message: 'Try a different keyword or adjust your filters.',
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.results.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Material(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        }

        if (index == state.results.length + 1) {
          return _buildFooter(
            loadingMore: state.loadingMore,
            hasMore: state.hasMore,
            loadedCount: state.results.length,
            totalCount: state.totalCount,
          );
        }

        final item = state.results[index - 1];
        return SearchResultCard(
          item: item,
          onOpenDirections: _openDirections,
          onCloseParentSearchSheet: _closeParentSearchSheet,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final query = _textController.text.trim();

    if (_textController.text != state.query) {
      _textController.value = _textController.value.copyWith(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
        composing: TextRange.empty,
      );
    }

    return RefreshIndicator(
      onRefresh: _reloadCurrentResults,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _textController,
              autofocus: true,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search events',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        onPressed: () async {
                          _debounce?.cancel();
                          await ref.read(searchControllerProvider.notifier).clearQuery();
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppChip(
                    label: state.hasActiveFilters ? 'Filtered' : 'Filter',
                    onTap: _openFilterSheet,
                    selected: state.hasActiveFilters,
                    icon: Icons.tune_rounded,
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: state.sort.label,
                    onTap: _openSortSheet,
                    selected: true,
                    icon: Icons.swap_vert_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}