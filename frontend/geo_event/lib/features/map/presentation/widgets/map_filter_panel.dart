import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import 'map_filter_widgets.dart';

@immutable
class _SegmentViewData {
  final int id;
  final String name;
  final String? color;

  const _SegmentViewData({
    required this.id,
    required this.name,
    this.color,
  });
}

@immutable
class _GenreViewData {
  final int id;
  final String name;

  const _GenreViewData({
    required this.id,
    required this.name,
  });
}

@immutable
class _SubGenreViewData {
  final int id;
  final String name;

  const _SubGenreViewData({
    required this.id,
    required this.name,
  });
}

class MapFilterPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<MapFilterSelection> onApply;
  final MapFilterSelection initialSelection;

  const MapFilterPanel({
    super.key,
    required this.onClose,
    required this.onApply,
    this.initialSelection = const MapFilterSelection(),
  });

  @override
  ConsumerState<MapFilterPanel> createState() => _MapFilterPanelState();
}

class _MapFilterPanelState extends ConsumerState<MapFilterPanel>
    with SingleTickerProviderStateMixin {
  static const double _priceMax = 500;
  static const double _minPanelWidth = 280;
  static const double _maxPanelWidth = 360;
  static const double _panelMinHeight = 460;
  static const double _panelMaxHeight = 720;

  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  late MapFilterSelection _selection;

  List<_SegmentViewData> _segments = [];
  List<_GenreViewData> _genres = [];
  List<_SubGenreViewData> _subGenres = [];

  bool _loadingSegments = true;
  bool _loadingGenres = false;
  bool _loadingSubGenres = false;
  String? _error;

  RangeValues get _priceRange => RangeValues(
        (_selection.minPrice ?? 0).clamp(0, _priceMax),
        (_selection.maxPrice ?? _priceMax).clamp(0, _priceMax),
      );

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didUpdateWidget(covariant MapFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSelection != widget.initialSelection) {
      setState(() {
        _selection = widget.initialSelection;
      });
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logLoadError(
    String message, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    AppLogger.error(
      message,
      tag: 'MapFilterPanel',
      error: error,
      stackTrace: stackTrace,
    );
  }

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

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _loadingSegments = true;
      _loadingGenres = false;
      _loadingSubGenres = false;
      _error = null;
      _genres = [];
      _subGenres = [];
    });

    try {
      final api = ref.read(eventsApiProvider);
      final rawSegments = await api.getSegments();

      final segments = rawSegments
          .whereType<dynamic>()
          .map<_SegmentViewData?>((item) {
            final id = item.segmentId;
            final name = item.name;
            if (id == null || name == null || name.toString().trim().isEmpty) {
              return null;
            }

            return _SegmentViewData(
              id: id,
              name: name.toString().trim(),
              color: item.color?.toString(),
            );
          })
          .whereType<_SegmentViewData>()
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _segments = segments;
        _loadingSegments = false;
      });

      if (_selection.segmentId != null) {
        await _loadGenres(_selection.segmentId!, keepSelection: true);
      }

      if (_selection.genreId != null) {
        await _loadSubGenres(_selection.genreId!, keepSelection: true);
      }
    } catch (error, stackTrace) {
      _logLoadError(
        'Failed to load initial map filter data.',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _loadingSegments = false;
        _error = _mapErrorMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Unable to load filter options.',
        );
      });
    }
  }

  Future<void> _loadGenres(int segmentId, {bool keepSelection = false}) async {
    if (!mounted) return;

    setState(() {
      _loadingGenres = true;
      _error = null;
      _genres = [];
      _subGenres = [];
      _selection = _selection.copyWith(
        segmentId: segmentId,
        clearGenre: !keepSelection,
        clearSubGenre: !keepSelection,
      );
    });

    try {
      final api = ref.read(eventsApiProvider);
      final rawGenres = await api.getGenresBySegment(segmentId);

      final genres = rawGenres
          .whereType<dynamic>()
          .map<_GenreViewData?>((item) {
            final id = item.genreId;
            final name = item.name;
            if (id == null || name == null || name.toString().trim().isEmpty) {
              return null;
            }

            return _GenreViewData(
              id: id,
              name: name.toString().trim(),
            );
          })
          .whereType<_GenreViewData>()
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _genres = genres;
        _loadingGenres = false;
      });
    } catch (error, stackTrace) {
      _logLoadError(
        'Failed to load genres.',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _loadingGenres = false;
        _error = _mapErrorMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Unable to load genres.',
        );
      });
    }
  }

  Future<void> _loadSubGenres(int genreId, {bool keepSelection = false}) async {
    if (!mounted) return;

    setState(() {
      _loadingSubGenres = true;
      _error = null;
      _subGenres = [];
      _selection = _selection.copyWith(
        genreId: genreId,
        clearSubGenre: !keepSelection,
      );
    });

    try {
      final api = ref.read(eventsApiProvider);
      final rawSubGenres = await api.getSubGenresByGenre(genreId);

      final subGenres = rawSubGenres
          .whereType<dynamic>()
          .map<_SubGenreViewData?>((item) {
            final id = item.subGenreId;
            final name = item.name;
            if (id == null || name == null || name.toString().trim().isEmpty) {
              return null;
            }

            return _SubGenreViewData(
              id: id,
              name: name.toString().trim(),
            );
          })
          .whereType<_SubGenreViewData>()
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _subGenres = subGenres;
        _loadingSubGenres = false;
      });
    } catch (error, stackTrace) {
      _logLoadError(
        'Failed to load subgenres.',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _loadingSubGenres = false;
        _error = _mapErrorMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Unable to load subgenres.',
        );
      });
    }
  }

  String _buildPriceLabel() {
    if (_selection.freeOnly) return 'Free only';

    final min = _selection.minPrice;
    final max = _selection.maxPrice;

    if (min == null && max == null) return 'Any price';
    if (min == null) return 'Up to \$${max!.round()}';
    if (max == null) return '\$${min.round()} and above';
    return '\$${min.round()} – \$${max.round()}';
  }

  IconData _segmentIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('music') || value.contains('concert')) {
      return Icons.music_note_rounded;
    }
    if (value.contains('sport')) {
      return Icons.sports_soccer_rounded;
    }
    if (value.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('art')) {
      return Icons.palette_rounded;
    }
    if (value.contains('tech')) {
      return Icons.computer_rounded;
    }
    if (value.contains('outdoor')) {
      return Icons.park_rounded;
    }
    if (value.contains('social')) {
      return Icons.people_rounded;
    }

    return Icons.apps_rounded;
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  Future<void> _apply() async {
    widget.onApply(_selection);
    await _close();
  }

  void _reset() {
    setState(() {
      _selection = const MapFilterSelection.defaults();
      _genres = [];
      _subGenres = [];
      _error = null;
      _loadingGenres = false;
      _loadingSubGenres = false;
    });
  }

  void _clearSegmentSelection() {
    setState(() {
      _selection = _selection.copyWith(
        clearSegment: true,
        clearGenre: true,
        clearSubGenre: true,
      );
      _genres = [];
      _subGenres = [];
      _error = null;
    });
  }

  void _clearGenreSelection() {
    setState(() {
      _selection = _selection.copyWith(
        clearGenre: true,
        clearSubGenre: true,
      );
      _subGenres = [];
      _error = null;
    });
  }

  void _clearSubGenreSelection() {
    setState(() {
      _selection = _selection.copyWith(clearSubGenre: true);
      _error = null;
    });
  }

  void _updateRadius(double value) {
    setState(() {
      _selection = _selection.copyWith(radiusKm: value);
    });
  }

  void _toggleGlobal(bool value) {
    setState(() {
      _selection = _selection.copyWith(showGlobalEvents: value);
    });
  }

  void _toggleFreeOnly(bool value) {
    setState(() {
      _selection = _selection.copyWith(
        freeOnly: value,
        clearMinPrice: value,
        clearMaxPrice: value,
      );
    });
  }

  void _toggleTodayOnly(bool value) {
    setState(() {
      _selection = _selection.copyWith(todayOnly: value);
    });
  }

  void _togglePreferences(bool value) {
    setState(() {
      _selection = _selection.copyWith(usePreferences: value);
    });
  }

  void _updatePriceRange(RangeValues values) {
    setState(() {
      _selection = _selection.copyWith(
        minPrice: values.start > 0 ? values.start : null,
        maxPrice: values.end < _priceMax ? values.end : null,
        clearMinPrice: values.start == 0,
        clearMaxPrice: values.end == _priceMax,
        freeOnly: false,
      );
    });
  }

  Widget _buildSegmentSection() {
    return MapFilterGroupCard(
      title: 'Segment',
      child: _loadingSegments
          ? const MapLoadingState()
          : _error != null
              ? MapFilterErrorText(message: _error!)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MapChoicePill(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      selected: _selection.segmentId == null,
                      onTap: _clearSegmentSelection,
                    ),
                    ..._segments.map((segment) {
                      final selected = _selection.segmentId == segment.id;

                      return MapChoicePill(
                        label: segment.name,
                        icon: _segmentIcon(segment.name),
                        selected: selected,
                        onTap: () async {
                          if (selected) return;
                          await _loadGenres(segment.id);
                        },
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildGenreSection() {
    return MapFilterGroupCard(
      title: 'Genre',
      child: _loadingGenres
          ? const MapLoadingState()
          : _error != null
              ? MapFilterErrorText(message: _error!)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MapChoicePill(
                      label: 'All',
                      selected: _selection.genreId == null,
                      onTap: _clearGenreSelection,
                    ),
                    ..._genres.map((genre) {
                      final selected = _selection.genreId == genre.id;

                      return MapChoicePill(
                        label: genre.name,
                        selected: selected,
                        onTap: () async {
                          if (selected) return;
                          await _loadSubGenres(genre.id);
                        },
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildSubGenreSection() {
    return MapFilterGroupCard(
      title: 'Subgenre',
      child: _loadingSubGenres
          ? const MapLoadingState()
          : _error != null
              ? MapFilterErrorText(message: _error!)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MapChoicePill(
                      label: 'All',
                      selected: _selection.subGenreId == null,
                      onTap: _clearSubGenreSelection,
                    ),
                    ..._subGenres.map((subGenre) {
                      final selected = _selection.subGenreId == subGenre.id;

                      return MapChoicePill(
                        label: subGenre.name,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selection = _selection.copyWith(
                              subGenreId: subGenre.id,
                            );
                          });
                        },
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildCategoriesSection() {
    return MapFilterSection(
      title: 'Categories',
      children: [
        _buildSegmentSection(),
        _buildGenreSection(),
        _buildSubGenreSection(),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return MapFilterSection(
      title: 'Distance',
      children: [
        MapSliderCard(
          label: _selection.showGlobalEvents
              ? 'Global events enabled'
              : 'Radius ${_selection.radiusKm.round()} km',
          value: _selection.radiusKm,
          min: 1,
          max: 500,
          divisions: 99,
          enabled: !_selection.showGlobalEvents,
          onChanged: _updateRadius,
        ),
        MapToggleCard(
          label: 'Show global events',
          subtitle:
              'Disable distance filtering and show events from anywhere.',
          value: _selection.showGlobalEvents,
          onChanged: _toggleGlobal,
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return MapFilterSection(
      title: 'Price',
      children: [
        MapRangeSliderCard(
          label: _buildPriceLabel(),
          values: _priceRange,
          min: 0,
          max: _priceMax,
          divisions: 100,
          onChanged: _selection.freeOnly ? (_) {} : _updatePriceRange,
        ),
        if (_selection.freeOnly)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Price range is disabled while free-only is enabled.',
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return MapFilterSection(
      title: 'Options',
      children: [
        MapToggleCard(
          label: 'Free events only',
          subtitle: 'Only show events with no ticket price.',
          value: _selection.freeOnly,
          onChanged: _toggleFreeOnly,
        ),
        MapToggleCard(
          label: 'Today only',
          subtitle: 'Only show events happening today.',
          value: _selection.todayOnly,
          onChanged: _toggleTodayOnly,
        ),
        MapToggleCard(
          label: 'Use my preferences',
          subtitle: 'Blend map results with your saved interests.',
          value: _selection.usePreferences,
          onChanged: _togglePreferences,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Apply filters',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width * 0.78;

    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 80),
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: width.clamp(_minPanelWidth, _maxPanelWidth),
                  constraints: const BoxConstraints(
                    minHeight: _panelMinHeight,
                    maxHeight: _panelMaxHeight,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161A21)
                        : const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A303A)
                          : const Color(0xFFE3EAF3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.08,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MapFilterPanelHeader(onClose: _close),
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF2A303A)
                            : const Color(0xFFE3EAF3),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoriesSection(),
                              const SizedBox(height: 18),
                              _buildDistanceSection(),
                              const SizedBox(height: 18),
                              _buildPriceSection(),
                              const SizedBox(height: 18),
                              _buildOptionsSection(),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF2A303A)
                            : const Color(0xFFE3EAF3),
                      ),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}