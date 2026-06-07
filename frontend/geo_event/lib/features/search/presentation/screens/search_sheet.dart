import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../domain/filter_selection.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_sheet_chip.dart';

class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

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

  String _sortBy = 'StartDateTime';
  bool _sortDescending = false;

  int _requestId = 0;

  bool get _hasActiveFilters =>
      _selectedSegmentId != null ||
      _selectedGenreId != null ||
      _selectedSubGenreId != null;

  String get _query => _textController.text.trim();

  String get _sortLabel {
    if (_sortBy == 'LikesCount' && _sortDescending) return 'Most liked';
    if (_sortBy == 'ViewCount' && _sortDescending) return 'Most viewed';
    if (_sortBy == 'Price' && !_sortDescending) return 'Lowest price';
    if (_sortBy == 'Price' && _sortDescending) return 'Highest price';
    if (_sortBy == 'StartDateTime' && !_sortDescending) return 'Soonest';
    if (_sortBy == 'StartDateTime' && _sortDescending) return 'Latest';
    return 'Sort';
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

  void _onQueryChanged(String value) {
    setState(() {});
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

  Map<int, double> _segmentWeights(List<dynamic> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final segmentId = pref.segmentId as int?;
      if (segmentId != null) {
        map[segmentId] = (map[segmentId] ?? 0) + (pref.score as num).toDouble();
      }
    }

    return map;
  }

  Map<int, double> _genreWeights(List<dynamic> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final genreId = pref.genreId as int?;
      if (genreId != null) {
        map[genreId] = (map[genreId] ?? 0) + (pref.score as num).toDouble();
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

  Future<void> _loadInitialResults({bool force = false}) async {
    if (!force && _results.isNotEmpty && _query.isEmpty) return;

    final requestId = ++_requestId;

    setState(() {
      _loading = true;
      _error = null;
    });

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

      final preferences = <dynamic>[];
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

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = ranked;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      await _loadInitialResults(force: true);
      return;
    }

    final requestId = ++_requestId;

    setState(() {
      _loading = true;
      _error = null;
    });

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

      final ranked = [...items]..sort((a, b) => score(b).compareTo(score(a)));

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = ranked;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<_SortOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF161A21) : Colors.white;
        final border = isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3);

        Widget tile({
          required String title,
          required _SortOption value,
        }) {
          final active = _sortBy == value.sortBy &&
              _sortDescending == value.sortDescending;

          return ListTile(
            onTap: () => Navigator.pop(context, value),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: active
                ? const Icon(Icons.check_rounded, color: Color(0xFF6B8FBF))
                : null,
          );
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white24
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sort events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                tile(
                  title: 'Soonest',
                  value: const _SortOption(
                    sortBy: 'StartDateTime',
                    sortDescending: false,
                  ),
                ),
                tile(
                  title: 'Latest',
                  value: const _SortOption(
                    sortBy: 'StartDateTime',
                    sortDescending: true,
                  ),
                ),
                tile(
                  title: 'Most liked',
                  value: const _SortOption(
                    sortBy: 'LikesCount',
                    sortDescending: true,
                  ),
                ),
                tile(
                  title: 'Most viewed',
                  value: const _SortOption(
                    sortBy: 'ViewCount',
                    sortDescending: true,
                  ),
                ),
                tile(
                  title: 'Lowest price',
                  value: const _SortOption(
                    sortBy: 'Price',
                    sortDescending: false,
                  ),
                ),
                tile(
                  title: 'Highest price',
                  value: const _SortOption(
                    sortBy: 'Price',
                    sortDescending: true,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _sortBy = selected.sortBy;
      _sortDescending = selected.sortDescending;
    });

    if (_query.isEmpty) {
      await _loadInitialResults(force: true);
    } else {
      await _search(_query);
    }
  }

  Future<void> _openFilterSheet() async {
    final segments = await ref.read(eventsApiProvider).getSegments();

    if (!mounted) return;

    final result = await showModalBottomSheet<FilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SearchFilterBottomSheet(
          initialSegmentId: _selectedSegmentId,
          initialGenreId: _selectedGenreId,
          initialSubGenreId: _selectedSubGenreId,
          segments: segments,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedSegmentId = result.segmentId;
      _selectedGenreId = result.genreId;
      _selectedSubGenreId = result.subGenreId;
    });

    if (_query.isEmpty) {
      await _loadInitialResults(force: true);
    } else {
      await _search(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = _query;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _textController,
            autofocus: true,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search events',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      onPressed: () async {
                        _debounce?.cancel();
                        _textController.clear();
                        setState(() {});
                        await _loadInitialResults(force: true);
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SearchSheetChip(
                label: _hasActiveFilters ? 'Filtered' : 'Filter...',
                isDark: isDark,
                onTap: _openFilterSheet,
                isSelected: _hasActiveFilters,
              ),
              const SizedBox(width: 8),
              SearchSheetChip(
                label: _sortLabel,
                isDark: isDark,
                onTap: _openSortSheet,
                isSelected: _sortLabel != 'Sort',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Center(
              child: Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (query.isEmpty && _results.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Center(
              child: Text(
                'No events available right now.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (query.isNotEmpty && _results.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Center(
              child: Text(
                'No events found.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._results.map((item) => SearchResultCard(item: item)),
      ],
    );
  }
}

class _SortOption {
  final String sortBy;
  final bool sortDescending;

  const _SortOption({
    required this.sortBy,
    required this.sortDescending,
  });
}