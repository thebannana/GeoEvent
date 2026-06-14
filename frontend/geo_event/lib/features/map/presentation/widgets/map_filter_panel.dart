import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import 'map_filter_controls.dart';

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
        _selection.minPrice ?? 0,
        _selection.maxPrice ?? _priceMax,
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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _loadingSegments = true;
      _error = null;
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
          .toList();

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSegments = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadGenres(int segmentId, {bool keepSelection = false}) async {
    if (!mounted) return;

    setState(() {
      _loadingGenres = true;
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
          .toList();

      if (!mounted) return;

      setState(() {
        _genres = genres;
        _loadingGenres = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGenres = false;
      });
    }
  }

  Future<void> _loadSubGenres(int genreId, {bool keepSelection = false}) async {
    if (!mounted) return;

    setState(() {
      _loadingSubGenres = true;
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
          .toList();

      if (!mounted) return;

      setState(() {
        _subGenres = subGenres;
        _loadingSubGenres = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSubGenres = false;
      });
    }
  }

  String _buildPriceLabel() {
    final min = _selection.minPrice;
    final max = _selection.maxPrice;

    if (min == null && max == null) return 'Any price';
    if (min == null) return 'Up to \$${max!.round()}';
    if (max == null) return '\$${min.round()} and above';
    return '\$${min.round()} – \$${max.round()}';
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
      _selection = MapFilterSelection.defaults();
      _genres = [];
      _subGenres = [];
    });
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
                  width: width.clamp(280.0, 360.0),
                  constraints: const BoxConstraints(
                    minHeight: 460,
                    maxHeight: 720,
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
                              MapFilterSection(
                                title: 'Categories',
                                children: [
                                  MapFilterGroupCard(
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
                                                    selected:
                                                        _selection.segmentId == null,
                                                    onTap: () {
                                                      setState(() {
                                                        _selection = _selection.copyWith(
                                                          clearSegment: true,
                                                          clearGenre: true,
                                                          clearSubGenre: true,
                                                        );
                                                        _genres = [];
                                                        _subGenres = [];
                                                      });
                                                    },
                                                  ),
                                                  ..._segments.map((segment) {
                                                    final selected =
                                                        _selection.segmentId ==
                                                            segment.id;
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
                                  ),
                                  MapFilterGroupCard(
                                    title: 'Genre',
                                    child: _loadingGenres
                                        ? const MapLoadingState()
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              MapChoicePill(
                                                label: 'All',
                                                selected: _selection.genreId == null,
                                                onTap: () {
                                                  setState(() {
                                                    _selection = _selection.copyWith(
                                                      clearGenre: true,
                                                      clearSubGenre: true,
                                                    );
                                                    _subGenres = [];
                                                  });
                                                },
                                              ),
                                              ..._genres.map((genre) {
                                                return MapChoicePill(
                                                  label: genre.name,
                                                  selected:
                                                      _selection.genreId == genre.id,
                                                  onTap: () async {
                                                    if (_selection.genreId ==
                                                        genre.id) {
                                                      return;
                                                    }
                                                    await _loadSubGenres(genre.id);
                                                  },
                                                );
                                              }),
                                            ],
                                          ),
                                  ),
                                  MapFilterGroupCard(
                                    title: 'Subgenre',
                                    child: _loadingSubGenres
                                        ? const MapLoadingState()
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              MapChoicePill(
                                                label: 'All',
                                                selected:
                                                    _selection.subGenreId == null,
                                                onTap: () {
                                                  setState(() {
                                                    _selection = _selection.copyWith(
                                                      clearSubGenre: true,
                                                    );
                                                  });
                                                },
                                              ),
                                              ..._subGenres.map((subGenre) {
                                                return MapChoicePill(
                                                  label: subGenre.name,
                                                  selected:
                                                      _selection.subGenreId ==
                                                          subGenre.id,
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              MapFilterSection(
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
                                    onChanged: (value) => setState(
                                      () => _selection =
                                          _selection.copyWith(radiusKm: value),
                                    ),
                                  ),
                                  MapToggleCard(
                                    label: 'Show global events',
                                    subtitle:
                                        'Disable distance filtering and show events from anywhere.',
                                    value: _selection.showGlobalEvents,
                                    onChanged: (v) => setState(
                                      () => _selection = _selection.copyWith(
                                        showGlobalEvents: v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              MapFilterSection(
                                title: 'Price',
                                children: [
                                  MapRangeSliderCard(
                                    label: _buildPriceLabel(),
                                    values: _priceRange,
                                    min: 0,
                                    max: _priceMax,
                                    divisions: 100,
                                    onChanged: (values) {
                                      setState(() {
                                        _selection = _selection.copyWith(
                                          minPrice:
                                              values.start > 0 ? values.start : null,
                                          maxPrice: values.end < _priceMax
                                              ? values.end
                                              : null,
                                          clearMinPrice: values.start == 0,
                                          clearMaxPrice: values.end == _priceMax,
                                          freeOnly: false,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              MapFilterSection(
                                title: 'Options',
                                children: [
                                  MapToggleCard(
                                    label: 'Free events only',
                                    subtitle:
                                        'Only show events with no ticket price.',
                                    value: _selection.freeOnly,
                                    onChanged: (v) {
                                      setState(() {
                                        _selection = _selection.copyWith(
                                          freeOnly: v,
                                          clearMinPrice: v,
                                          clearMaxPrice: v,
                                        );
                                      });
                                    },
                                  ),
                                  MapToggleCard(
                                    label: 'Today only',
                                    subtitle:
                                        'Only show events happening today.',
                                    value: _selection.todayOnly,
                                    onChanged: (v) {
                                      setState(() {
                                        _selection =
                                            _selection.copyWith(todayOnly: v);
                                      });
                                    },
                                  ),
                                  MapToggleCard(
                                    label: 'Use my preferences',
                                    subtitle:
                                        'Blend map results with your saved interests.',
                                    value: _selection.usePreferences,
                                    onChanged: (v) {
                                      setState(() {
                                        _selection = _selection.copyWith(
                                          usePreferences: v,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
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
                      Padding(
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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