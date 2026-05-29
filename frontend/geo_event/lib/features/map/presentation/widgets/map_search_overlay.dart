import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/data/events_api.dart';
import '../../../../shared/events/models/create_event_models.dart';

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
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _textController.addListener(_onQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyInitial();
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
        await _loadNearbyInitial(force: true);
      } else {
        await _search(query);
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNearbyInitial({bool force = false}) async {
    if (_loadedInitialNearby && !force) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ref.read(eventsApiProvider).getNearbyEvents(
            latitude: widget.userLatitude,
            longitude: widget.userLongitude,
            radiusKm: 25,
            limit: 20,
          );

      final ranked = _rankByPreferences(items);

      if (!mounted) return;
      setState(() {
        _results = ranked;
        _loading = false;
        _loadedInitialNearby = true;
      });
    } catch (e) {
      if (!mounted) return;
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
      await _loadNearbyInitial(force: true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ref.read(eventsApiProvider).searchEvents(
            searchTerm: trimmed,
            page: 1,
            pageSize: 20,
          );

      final ranked = _rankSearchResults(items, trimmed);

      if (!mounted) return;
      setState(() {
        _results = ranked;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<EventItem> _rankByPreferences(List<EventItem> items) {
    final ranked = [...items];
    ranked.sort((a, b) => _preferenceScore(b).compareTo(_preferenceScore(a)));
    return ranked;
  }

  List<EventItem> _rankSearchResults(List<EventItem> items, String query) {
    final q = query.toLowerCase();
    final ranked = [...items];

    int score(EventItem item) {
      var total = 0;

      final title = item.title.toLowerCase();
      final segment = (item.segmentName ?? '').toLowerCase();
      final genre = (item.genreName ?? '').toLowerCase();
      final subGenre = (item.subGenreName ?? '').toLowerCase();
      final tags = (item.tags ?? '').toLowerCase();

      if (title.contains(q)) total += 80;
      if (segment.contains(q)) total += 30;
      if (genre.contains(q)) total += 25;
      if (subGenre.contains(q)) total += 20;
      if (tags.contains(q)) total += 15;

      total += _preferenceScore(item);
      total += (item.likesCount / 20).round();
      total += (item.viewCount / 200).round();

      return total;
    }

    ranked.sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }

  int _preferenceScore(EventItem item) {
    var score = 0;

    if (item.segmentId != null &&
        widget.preferredSegmentIds.contains(item.segmentId)) {
      score += 30;
    }
    if (item.genreId != null &&
        widget.preferredGenreIds.contains(item.genreId)) {
      score += 22;
    }
    if (item.subGenreId != null &&
        widget.preferredSubGenreIds.contains(item.subGenreId)) {
      score += 16;
    }
    if (item.isFeatured) {
      score += 6;
    }

    return score;
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final hasQuery = _textController.text.trim().isNotEmpty;

    return SlideTransition(
      position: _slide,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 118),
        child: Container(
          height: size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.circular(28),
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _close,
                      icon: const Icon(Icons.close_rounded),
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
                              _loadNearbyInitial(force: true);
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
                    _DropChip(label: hasQuery ? 'Category' : 'Nearby'),
                    const SizedBox(width: 8),
                    _DropChip(label: hasQuery ? 'Sort' : 'For you'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _results.isEmpty
                            ? Center(
                                child: Text(
                                  hasQuery
                                      ? 'No events found.'
                                      : 'No nearby events found.',
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, i) {
                                  final item = _results[i];
                                  return _EventCard(item: item);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  final String label;

  const _DropChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem item;

  const _EventCard({required this.item});

  Color _segmentColor() {
    final name = (item.segmentName ?? '').toLowerCase();

    if (name.contains('concert') || name.contains('music')) {
      return const Color(0xFF5E7BFF);
    }
    if (name.contains('sport')) {
      return const Color(0xFFFF5A76);
    }
    if (name.contains('education') || name.contains('seminar')) {
      return const Color(0xFF68C95A);
    }
    return const Color(0xFF6B8FBF);
  }

  String _formatPrice() {
    if (item.price <= 0) return 'Free';
    if (item.price % 1 == 0) return '${item.price.toInt()}\$';
    return '${item.price.toStringAsFixed(2)}\$';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _segmentColor();

    final subtitleParts = <String>[
      if ((item.promoterName ?? '').isNotEmpty) 'By: ${item.promoterName}',
      if ((item.genreName ?? '').isNotEmpty) item.genreName!,
    ];

    final subtitle = subtitleParts.join(' · ');
    final imageUrl = item.coverImageUrl ??
        (item.imageUrls.isNotEmpty ? item.imageUrls.first : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 102,
                  height: 96,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: accent.withValues(alpha: 0.90),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.event_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: accent.withValues(alpha: 0.90),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.event_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.segmentName != null && item.segmentName!.isNotEmpty
                            ? '${item.segmentName}: ${item.title}'
                            : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle.isEmpty ? 'Event' : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likesCount} likes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.viewCount} views',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Price: ${_formatPrice()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 4,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}