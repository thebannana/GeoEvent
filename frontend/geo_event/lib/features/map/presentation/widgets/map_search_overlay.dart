import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../../../core/widgets/app_icon_circle_button.dart';
import '../../../../shared/events/models/create_event_models.dart'
    hide rankByPreferences, isWithinRadius, rankSearchResults;
import '../../../../shared/events/providers/event_providers.dart';
import 'map_search_helpers.dart';
import 'map_search_widgets.dart';

class MapSearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final double userLatitude;
  final double userLongitude;
  final Set<int> preferredSegmentIds;
  final Set<int> preferredGenreIds;
  final Set<int> preferredSubGenreIds;

  const MapSearchOverlay({
    super.key,
    required this.onClose,
    required this.userLatitude,
    required this.userLongitude,
    this.preferredSegmentIds = const {},
    this.preferredGenreIds = const {},
    this.preferredSubGenreIds = const {},
  });

  @override
  ConsumerState<MapSearchOverlay> createState() => _MapSearchOverlayState();
}

class _MapSearchOverlayState extends ConsumerState<MapSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  final TextEditingController _textController = TextEditingController();

  Timer? _debounce;
  List<EventItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _loadedInitialNearby = false;
  int _requestId = 0;
  bool _closing = false;

  static const List<double> _distanceOptions = [25, 50, 100, 250];
  double _selectedRadiusKm = 25;
  bool _showGlobalEvents = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 270),
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
    _debounce?.cancel();
    _controller.dispose();
    _textController.removeListener(_onQueryChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = _textController.text.trim();

      if (query.isEmpty) {
        await _loadInitial(force: true);
      } else {
        await _search(query);
      }
    });

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadInitial({bool force = false}) async {
    if (_loadedInitialNearby && !force && !_showGlobalEvents) return;

    if (_showGlobalEvents) {
      await _loadGlobalInitial();
    } else {
      await _loadNearbyInitial(force: force);
    }
  }

  Future<void> _loadNearbyInitial({bool force = false}) async {
    if (_loadedInitialNearby && !force) return;

    final requestId = ++_requestId;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

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

      setState(() {
        _results = ranked;
        _loading = false;
        _error = null;
        _loadedInitialNearby = true;
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

  Future<void> _loadGlobalInitial() async {
    final requestId = ++_requestId;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

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

      setState(() {
        _results = ranked;
        _loading = false;
        _error = null;
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
      await _loadInitial(force: true);
      return;
    }

    final requestId = ++_requestId;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

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

      setState(() {
        _results = ranked;
        _loading = false;
        _error = null;
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

  Future<void> _applyRadius(double radiusKm) async {
    if (_selectedRadiusKm == radiusKm && !_showGlobalEvents) return;

    setState(() {
      _selectedRadiusKm = radiusKm;
      _showGlobalEvents = false;
      _loadedInitialNearby = false;
    });

    final query = _textController.text.trim();
    if (query.isEmpty) {
      await _loadNearbyInitial(force: true);
    } else {
      await _search(query);
    }
  }

  Future<void> _toggleGlobal() async {
    setState(() {
      _showGlobalEvents = !_showGlobalEvents;
      _loadedInitialNearby = false;
    });

    final query = _textController.text.trim();
    if (query.isEmpty) {
      await _loadInitial(force: true);
    } else {
      await _search(query);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;

    _debounce?.cancel();
    _requestId++;

    await _controller.reverse();

    if (!mounted) return;
    widget.onClose();
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
                  trailing: _selectedRadiusKm == km && !_showGlobalEvents
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

  @override
  Widget build(BuildContext context) {
    final hasQuery = _textController.text.trim().isNotEmpty;

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
                      'Search',
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
                  hintText: 'Search events',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: hasQuery
                      ? IconButton(
                          onPressed: () {
                            _textController.clear();
                            _loadInitial(force: true);
                          },
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
                  MapSearchFilterChip(
                    label: _showGlobalEvents
                        ? 'Global'
                        : 'Within ${_selectedRadiusKm.toInt()} km',
                    onTap: _showDistancePicker,
                  ),
                  const SizedBox(width: 8),
                  MapSearchFilterChip(
                    label: _showGlobalEvents ? 'Global on' : 'Global off',
                    isActive: _showGlobalEvents,
                    onTap: _toggleGlobal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading) {
                    return const MapSearchLoadingView();
                  }
                  if (_error != null) {
                    return MapSearchErrorView(message: _error!);
                  }
                  if (_results.isEmpty) {
                    return MapSearchEmptyView(
                      hasQuery: hasQuery,
                      showGlobalEvents: _showGlobalEvents,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final item = _results[i];
                      return MapSearchEventCard(item: item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}