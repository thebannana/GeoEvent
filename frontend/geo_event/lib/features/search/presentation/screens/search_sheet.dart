import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/providers/directions_providers.dart';
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
  Timer? _debounce;

  List<EventItem> _results = [];
  bool _loading = false;
  String? _error;

  int? _selectedSegmentId;
  int? _selectedGenreId;
  int? _selectedSubGenreId;

  String _sortBy = 'Recommended';
  bool _sortDescending = true;

  int _requestId = 0;
  bool _isDialogOpen = false;

  bool get _hasActiveFilters =>
      _selectedSegmentId != null ||
      _selectedGenreId != null ||
      _selectedSubGenreId != null;

  String get _query => _textController.text.trim();

  String get _sortLabel {
    if (_sortBy == 'Recommended') return 'Recommended';
    if (_sortBy == 'LikesCount' && _sortDescending) return 'Most liked';
    if (_sortBy == 'ViewCount' && _sortDescending) return 'Most viewed';
    if (_sortBy == 'Price' && !_sortDescending) return 'Lowest price';
    if (_sortBy == 'Price' && _sortDescending) return 'Highest price';
    if (_sortBy == 'StartDateTime' && !_sortDescending) return 'Soonest';
    if (_sortBy == 'StartDateTime' && _sortDescending) return 'Latest';
    return 'Sort';
  }

  List<EventItem> _removeUnavailableEvents(List<EventItem> items) {
    return items.where((item) => item.isVisibleInSearch).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialResults();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _closeParentSearchSheet() {
    widget.onCloseSheet?.call();
  }

  void _setLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  void _setResults(List<EventItem> results) {
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
      _error = null;
    });
  }

  void _setError(Object error) {
    if (!mounted) return;
    setState(() {
      _results = [];
      _loading = false;
      _error = error.toString().replaceFirst('Exception: ', '');
    });
  }

  Future<void> _reloadCurrentResults() async {
    if (_query.isEmpty) {
      await _loadInitialResults(force: true);
    } else {
      await _search(_query);
    }
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

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = value.trim();
      if (query.isEmpty) {
        await _loadInitialResults(force: true);
      } else {
        await _search(query);
      }
    });
  }

  Future<void> _loadInitialResults({bool force = false}) async {
    if (!force && _results.isNotEmpty && _query.isEmpty) return;

    final requestId = ++_requestId;
    _setLoading();

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            page: 1,
            pageSize: 20,
            sortBy: _sortBy,
            sortDescending: _sortDescending,
            segmentId: _selectedSegmentId,
            genreId: _selectedGenreId,
            subGenreId: _selectedSubGenreId,
          );

      if (!mounted || requestId != _requestId) return;
      final visibleItems = _removeUnavailableEvents(items);
      _setResults(visibleItems);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _setError(e);
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      await _loadInitialResults(force: true);
      return;
    }

    final requestId = ++_requestId;
    _setLoading();

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            searchTerm: trimmed,
            page: 1,
            pageSize: 20,
            sortBy: _sortBy,
            sortDescending: _sortDescending,
            segmentId: _selectedSegmentId,
            genreId: _selectedGenreId,
            subGenreId: _selectedSubGenreId,
          );

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

        total += item.likesCount / 20;
        total += item.viewCount / 200;

        return total;
      }

      final visibleItems = _removeUnavailableEvents(items);
      final ranked = [...visibleItems]
        ..sort((a, b) => score(b).compareTo(score(a)));

      if (!mounted || requestId != _requestId) return;
      _setResults(ranked);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _setError(e);
    }
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
    final selected = await _showSheetSafeDialog<SortOption>(
      child: SearchSortBottomSheet(
        selected: SortOption(
          sortBy: _sortBy,
          sortDescending: _sortDescending,
          label: _sortLabel,
        ),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _sortBy = selected.sortBy;
      _sortDescending = selected.sortDescending;
    });

    await _reloadCurrentResults();
  }

  Future<void> _openFilterSheet() async {
    try {
      final segments = await ref.read(eventsApiProvider).getSegments();

      if (!mounted) return;

      final result = await _showSheetSafeDialog<FilterSelection>(
        child: SearchFilterBottomSheet(
          initialSegmentId: _selectedSegmentId,
          initialGenreId: _selectedGenreId,
          initialSubGenreId: _selectedSubGenreId,
          segments: segments,
        ),
      );

      if (result == null || !mounted) return;

      setState(() {
        _selectedSegmentId = result.segmentId;
        _selectedGenreId = result.genreId;
        _selectedSubGenreId = result.subGenreId;
      });

      await _reloadCurrentResults();
    } catch (e) {
      _setError(e);
    }
  }

  Widget _buildBody() {
    final query = _query;

    if (_loading && _results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppLoadingIndicator(
              title: 'Loading events',
              message: 'Please wait while we prepare your results.',
              centered: false,
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_error != null && _results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          AppErrorState(
            message: _error!,
            onRetry: _reloadCurrentResults,
          ),
        ],
      );
    }

    if (query.isEmpty && _results.isEmpty) {
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

    if (query.isNotEmpty && _results.isEmpty) {
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
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              if (_error != null)
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
                              _error!,
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        }

        final item = _results[index - 1];
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
    final query = _query;

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
                          _textController.clear();
                          if (mounted) setState(() {});
                          await _loadInitialResults(force: true);
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
                    label: _hasActiveFilters ? 'Filtered' : 'Filter',
                    onTap: _openFilterSheet,
                    selected: _hasActiveFilters,
                    icon: Icons.tune_rounded,
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: _sortLabel,
                    onTap: _openSortSheet,
                    selected: _sortLabel != 'Sort',
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