import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/inputs/app_icon_circle_button.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../shared/events/models/create_event_models.dart'
    hide isWithinRadius, rankByPreferences, rankSearchResults;
import '../../../../shared/events/providers/event_providers.dart';
import 'map_event_helpers.dart';
import 'map_search_widgets.dart';

class MapSearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final double userLatitude;
  final double userLongitude;
  final Set<int> preferredSegmentIds;
  final Set<int> preferredGenreIds;
  final Set<int> preferredSubGenreIds;
  final ValueChanged<EventItem>? onEventSelected;

  const MapSearchOverlay({
    super.key,
    required this.onClose,
    required this.userLatitude,
    required this.userLongitude,
    this.preferredSegmentIds = const {},
    this.preferredGenreIds = const {},
    this.preferredSubGenreIds = const {},
    this.onEventSelected,
  });

  @override
  ConsumerState<MapSearchOverlay> createState() => _MapSearchOverlayState();
}

class _MapSearchOverlayState extends ConsumerState<MapSearchOverlay>
    with SingleTickerProviderStateMixin {
  static const _debounceDuration = Duration(milliseconds: 350);
  static const _animationDuration = Duration(milliseconds: 270);
  static const List<double> _distanceOptions = [25, 50, 100, 250];

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  final TextEditingController _textController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: _debounceDuration);

  List<EventItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _loadedInitialNearby = false;
  int _requestId = 0;
  bool _closing = false;

  double _selectedRadiusKm = 25;
  bool _showGlobalEvents = false;

  bool get _hasQuery => _textController.text.trim().isNotEmpty;

  String get _query => _textController.text.trim();

  String get _scopeLabel => _showGlobalEvents
      ? 'Global results'
      : 'Nearby results within ${_selectedRadiusKm.toInt()} km';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _textController.addListener(_onQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _textController.removeListener(_onQueryChanged);
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debouncer.runAsync(() async {
      if (_query.isEmpty) {
        await _loadInitial(force: true);
      } else {
        await _search(_query);
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  int _beginRequest() => ++_requestId;

  String _mapErrorMessage(
    Object error, {
    StackTrace? stackTrace,
    String fallback = 'Something went wrong.',
  }) {
    return ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: fallback,
    );
  }

  void _logError(
    String message, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      message,
      tag: 'MapSearchOverlay',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _startLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  void _finishWithResults(
    List<EventItem> items, {
    bool markNearbyLoaded = false,
  }) {
    if (!mounted) return;
    setState(() {
      _results = items;
      _loading = false;
      _error = null;
      if (markNearbyLoaded) {
        _loadedInitialNearby = true;
      }
    });
  }

  void _finishWithError(
    Object error, {
    StackTrace? stackTrace,
    String fallback = 'Unable to load events.',
  }) {
    if (!mounted) return;
    setState(() {
      _results = [];
      _loading = false;
      _error = _mapErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: fallback,
      );
    });
  }

  Future<void> _loadInitial({bool force = false}) async {
    if (_showGlobalEvents) {
      await _loadGlobalInitial();
      return;
    }

    if (_loadedInitialNearby && !force) return;
    await _loadNearbyInitial(force: force);
  }

  Future<void> _loadNearbyInitial({bool force = false}) async {
    if (_loadedInitialNearby && !force) return;

    final requestId = _beginRequest();
    _startLoading();

    try {
      final items = await ref.read(eventsApiProvider).getNearbyEvents(
            latitude: widget.userLatitude,
            longitude: widget.userLongitude,
            radiusKm: _selectedRadiusKm,
            limit: 20,
          );

      if (!mounted || requestId != _requestId) return;

      final ranked = rankByPreferences(
        items: items,
        preferredSegmentIds: widget.preferredSegmentIds,
        preferredGenreIds: widget.preferredGenreIds,
        preferredSubGenreIds: widget.preferredSubGenreIds,
      );

      _finishWithResults(ranked, markNearbyLoaded: true);
    } catch (error, stackTrace) {
      if (!mounted || requestId != _requestId) return;

      _logError(
        'Failed to load nearby search results.',
        error: error,
        stackTrace: stackTrace,
      );

      _finishWithError(
        error,
        stackTrace: stackTrace,
        fallback: 'Unable to load nearby events.',
      );
    }
  }

  Future<void> _loadGlobalInitial() async {
    final requestId = _beginRequest();
    _startLoading();

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            page: 1,
            pageSize: 20,
          );

      if (!mounted || requestId != _requestId) return;

      final ranked = rankByPreferences(
        items: items,
        preferredSegmentIds: widget.preferredSegmentIds,
        preferredGenreIds: widget.preferredGenreIds,
        preferredSubGenreIds: widget.preferredSubGenreIds,
      );

      _finishWithResults(ranked);
    } catch (error, stackTrace) {
      if (!mounted || requestId != _requestId) return;

      _logError(
        'Failed to load global search results.',
        error: error,
        stackTrace: stackTrace,
      );

      _finishWithError(
        error,
        stackTrace: stackTrace,
        fallback: 'Unable to load global events.',
      );
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      await _loadInitial(force: true);
      return;
    }

    final requestId = _beginRequest();
    _startLoading();

    try {
      var items = await ref.read(eventsApiProvider).searchEvents(
            searchTerm: trimmed,
            page: 1,
            pageSize: 20,
          );

      if (!_showGlobalEvents) {
        items = items
            .where(
              (item) => isWithinRadius(
                item: item,
                userLatitude: widget.userLatitude,
                userLongitude: widget.userLongitude,
                radiusKm: _selectedRadiusKm,
              ),
            )
            .toList();
      }

      if (!mounted || requestId != _requestId) return;

      final ranked = rankSearchResults(
        items: items,
        query: trimmed,
        showGlobalEvents: _showGlobalEvents,
        selectedRadiusKm: _selectedRadiusKm,
        userLatitude: widget.userLatitude,
        userLongitude: widget.userLongitude,
        preferredSegmentIds: widget.preferredSegmentIds,
        preferredGenreIds: widget.preferredGenreIds,
        preferredSubGenreIds: widget.preferredSubGenreIds,
      );

      _finishWithResults(ranked);
    } catch (error, stackTrace) {
      if (!mounted || requestId != _requestId) return;

      _logError(
        'Failed to search events.',
        error: error,
        stackTrace: stackTrace,
      );

      _finishWithError(
        error,
        stackTrace: stackTrace,
        fallback: 'Unable to search events.',
      );
    }
  }

  Future<void> _refreshForCurrentMode() async {
    if (_query.isEmpty) {
      await _loadInitial(force: true);
    } else {
      await _search(_query);
    }
  }

  Future<void> _applyRadius(double radiusKm) async {
    if (_selectedRadiusKm == radiusKm && !_showGlobalEvents) return;

    setState(() {
      _selectedRadiusKm = radiusKm;
      _showGlobalEvents = false;
      _loadedInitialNearby = false;
    });

    await _refreshForCurrentMode();
  }

  Future<void> _toggleGlobal() async {
    setState(() {
      _showGlobalEvents = !_showGlobalEvents;
      _loadedInitialNearby = false;
    });

    await _refreshForCurrentMode();
  }

  Future<void> _clearQuery() async {
    _textController.clear();
    await _loadInitial(force: true);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;

    _debouncer.cancel();
    _requestId++;

    await _controller.reverse();

    if (mounted) {
      widget.onClose();
    }
  }

  Future<void> _showDistancePicker() async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text(
                  'Select distance',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ..._distanceOptions.map(
                (km) => ListTile(
                  title: Text('${km.toInt()} km'),
                  subtitle: _showGlobalEvents && _selectedRadiusKm == km
                      ? const Text('Will apply when nearby mode is enabled')
                      : null,
                  trailing: _selectedRadiusKm == km
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(km),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      await _applyRadius(picked);
    }
  }

  Widget _buildResults() {
    if (_loading) {
      return const MapSearchLoadingView();
    }
    if (_error != null) {
      return MapSearchErrorView(message: _error!);
    }
    if (_results.isEmpty) {
      return MapSearchEmptyView(
        hasQuery: _hasQuery,
        showGlobalEvents: _showGlobalEvents,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];

        return MapSearchEventCard(
          item: item,
          userLatitude: widget.userLatitude,
          userLongitude: widget.userLongitude,
          onTap: widget.onEventSelected == null
              ? null
              : () => widget.onEventSelected!(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: AppBottomSheetContainer(
        maxHeightFactor: 0.78,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 118),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search events',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  AppIconCircleButton(
                    onPressed: _close,
                    tooltip: 'Close search',
                    size: 40,
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by title, segment, genre, or tag',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _hasQuery
                      ? IconButton(
                          onPressed: _clearQuery,
                          icon: const Icon(Icons.close_rounded, size: 18),
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
                  Expanded(
                    child: MapSearchFilterChip(
                      label: 'Radius: ${_selectedRadiusKm.toInt()} km',
                      onTap: _showDistancePicker,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MapSearchFilterChip(
                    label: _showGlobalEvents ? 'Global on' : 'Nearby only',
                    isActive: _showGlobalEvents,
                    onTap: _toggleGlobal,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _scopeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }
}