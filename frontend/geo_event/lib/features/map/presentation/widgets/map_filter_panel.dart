import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/providers/event_providers.dart';

@immutable
class MapFilterSelection {
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;
  final double radiusKm;
  final bool freeOnly;
  final bool todayOnly;
  final bool usePreferences;
  final double? minPrice;
  final double? maxPrice;

  const MapFilterSelection({
    this.segmentId,
    this.genreId,
    this.subGenreId,
    this.radiusKm = 10,
    this.freeOnly = false,
    this.todayOnly = false,
    this.usePreferences = true,
    this.minPrice,
    this.maxPrice,
  });

  MapFilterSelection copyWith({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    double? radiusKm,
    bool? freeOnly,
    bool? todayOnly,
    bool? usePreferences,
    double? minPrice,
    double? maxPrice,
    bool clearSegment = false,
    bool clearGenre = false,
    bool clearSubGenre = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return MapFilterSelection(
      segmentId: clearSegment ? null : (segmentId ?? this.segmentId),
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      subGenreId: clearSubGenre ? null : (subGenreId ?? this.subGenreId),
      radiusKm: radiusKm ?? this.radiusKm,
      freeOnly: freeOnly ?? this.freeOnly,
      todayOnly: todayOnly ?? this.todayOnly,
      usePreferences: usePreferences ?? this.usePreferences,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }

  bool get hasActiveFilters =>
      segmentId != null ||
      genreId != null ||
      subGenreId != null ||
      freeOnly ||
      todayOnly ||
      radiusKm != 10 ||
      !usePreferences ||
      minPrice != null ||
      maxPrice != null;

  factory MapFilterSelection.defaults() => const MapFilterSelection();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapFilterSelection &&
        other.segmentId == segmentId &&
        other.genreId == genreId &&
        other.subGenreId == subGenreId &&
        other.radiusKm == radiusKm &&
        other.freeOnly == freeOnly &&
        other.todayOnly == todayOnly &&
        other.usePreferences == usePreferences &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice;
  }

  @override
  int get hashCode => Object.hash(
        segmentId,
        genreId,
        subGenreId,
        radiusKm,
        freeOnly,
        todayOnly,
        usePreferences,
        minPrice,
        maxPrice,
      );
}

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

class _GenreViewData {
  final int id;
  final String name;

  const _GenreViewData({
    required this.id,
    required this.name,
  });
}

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

  Color? _segmentAccent(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Events',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Refine nearby event pins',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
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
                              _DrawerSection(
                                title: 'Categories',
                                children: [
                                  _FilterGroupCard(
                                    title: 'Segment',
                                    child: _loadingSegments
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : _error != null
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  _error!,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.error,
                                                  ),
                                                ),
                                              )
                                            : Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _ChoicePill(
                                                    label: 'All',
                                                    icon: Icons.apps_rounded,
                                                    selected: _selection.segmentId == null,
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
                                                        _selection.segmentId == segment.id;
                                                    return _ChoicePill(
                                                      label: segment.name,
                                                      icon: _segmentIcon(segment.name),
                                                      selected: selected,
                                                      accent: _segmentAccent(segment.color),
                                                      onTap: () async {
                                                        if (selected) return;
                                                        await _loadGenres(segment.id);
                                                      },
                                                    );
                                                  }),
                                                ],
                                              ),
                                  ),
                                  _FilterGroupCard(
                                    title: 'Genre',
                                    child: _loadingGenres
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _ChoicePill(
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
                                                return _ChoicePill(
                                                  label: genre.name,
                                                  selected: _selection.genreId == genre.id,
                                                  onTap: () async {
                                                    if (_selection.genreId == genre.id) return;
                                                    await _loadSubGenres(genre.id);
                                                  },
                                                );
                                              }),
                                            ],
                                          ),
                                  ),
                                  _FilterGroupCard(
                                    title: 'Subgenre',
                                    child: _loadingSubGenres
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _ChoicePill(
                                                label: 'All',
                                                selected: _selection.subGenreId == null,
                                                onTap: () {
                                                  setState(() {
                                                    _selection = _selection.copyWith(
                                                      clearSubGenre: true,
                                                    );
                                                  });
                                                },
                                              ),
                                              ..._subGenres.map((subGenre) {
                                                return _ChoicePill(
                                                  label: subGenre.name,
                                                  selected:
                                                      _selection.subGenreId == subGenre.id,
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
                              _DrawerSection(
                                title: 'Distance',
                                children: [
                                  _SliderCard(
                                    label: 'Radius: ${_selection.radiusKm.round()} km',
                                    value: _selection.radiusKm,
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    onChanged: (value) {
                                      setState(() {
                                        _selection = _selection.copyWith(radiusKm: value);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _DrawerSection(
                                title: 'Price',
                                children: [
                                  _RangeSliderCard(
                                    label: _buildPriceLabel(),
                                    values: _priceRange,
                                    min: 0,
                                    max: _priceMax,
                                    divisions: 100,
                                    onChanged: (values) {
                                      setState(() {
                                        _selection = _selection.copyWith(
                                          minPrice: values.start > 0 ? values.start : null,
                                          maxPrice: values.end < _priceMax ? values.end : null,
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
                              _DrawerSection(
                                title: 'Options',
                                children: [
                                  _ToggleCard(
                                    label: 'Free events only',
                                    subtitle: 'Only show events with no ticket price.',
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
                                  _ToggleCard(
                                    label: 'Today only',
                                    subtitle: 'Only show events happening today.',
                                    value: _selection.todayOnly,
                                    onChanged: (v) {
                                      setState(() {
                                        _selection = _selection.copyWith(todayOnly: v);
                                      });
                                    },
                                  ),
                                  _ToggleCard(
                                    label: 'Use my preferences',
                                    subtitle: 'Blend map results with your saved interests.',
                                    value: _selection.usePreferences,
                                    onChanged: (v) {
                                      setState(() {
                                        _selection =
                                            _selection.copyWith(usePreferences: v);
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

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _FilterGroupCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterGroupCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accent;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = accent ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = selected
        ? baseColor.withValues(alpha: 0.7)
        : isDark
            ? const Color(0xFF2A303A)
            : const Color(0xFFE3EAF3);

    final backgroundColor = selected
        ? baseColor.withValues(alpha: isDark ? 0.24 : 0.12)
        : Colors.transparent;

    final foregroundColor =
        selected ? baseColor : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? baseColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSliderCard extends StatelessWidget {
  final String label;
  final RangeValues values;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues> onChanged;

  const _RangeSliderCard({
    required this.label,
    required this.values,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final safeStart = values.start.clamp(min, max);
    final safeEnd = values.end.clamp(min, max);
    final safeValues = safeStart <= safeEnd
        ? RangeValues(safeStart, safeEnd)
        : RangeValues(safeEnd, safeStart);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          RangeSlider(
            values: safeValues,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: theme.colorScheme.primary,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${max.round()}+',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}