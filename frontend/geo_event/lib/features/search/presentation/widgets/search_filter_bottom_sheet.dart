import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/data/events_api.dart';
import '../../domain/filter_selection.dart';

class SearchFilterBottomSheet extends ConsumerStatefulWidget {
  final List<dynamic> segments;
  final int? initialSegmentId;
  final int? initialGenreId;
  final int? initialSubGenreId;

  const SearchFilterBottomSheet({
    super.key,
    required this.segments,
    required this.initialSegmentId,
    required this.initialGenreId,
    required this.initialSubGenreId,
  });

  @override
  ConsumerState<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState
    extends ConsumerState<SearchFilterBottomSheet> {
  int? _segmentId;
  int? _genreId;
  int? _subGenreId;

  List<dynamic> _genres = [];
  List<dynamic> _subGenres = [];
  bool _loadingGenres = false;
  bool _loadingSubGenres = false;

  @override
  void initState() {
    super.initState();
    _segmentId = widget.initialSegmentId;
    _genreId = widget.initialGenreId;
    _subGenreId = widget.initialSubGenreId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_segmentId != null) {
        await _loadGenres(_segmentId!);
      }
      if (_genreId != null) {
        await _loadSubGenres(_genreId!);
      }
    });
  }

  Future<void> _loadGenres(int segmentId) async {
    setState(() {
      _loadingGenres = true;
      _genres = [];
      _subGenres = [];
      _genreId = null;
      _subGenreId = null;
    });

    try {
      final items = await ref.read(eventsApiProvider).getGenresBySegment(segmentId);
      if (!mounted) return;
      setState(() {
        _genres = items;
        _loadingGenres = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGenres = false;
      });
    }
  }

  Future<void> _loadSubGenres(int genreId) async {
    setState(() {
      _loadingSubGenres = true;
      _subGenres = [];
      _subGenreId = null;
    });

    try {
      final items = await ref.read(eventsApiProvider).getSubGenresByGenre(genreId);
      if (!mounted) return;
      setState(() {
        _subGenres = items;
        _loadingSubGenres = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSubGenres = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161A21) : Colors.white;
    final border = isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3);

    Widget buildChoiceChip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
    }

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Column(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                children: [
                  const Text(
                    'Segment',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    children: [
                      buildChoiceChip(
                        label: 'All',
                        selected: _segmentId == null,
                        onTap: () {
                          setState(() {
                            _segmentId = null;
                            _genreId = null;
                            _subGenreId = null;
                            _genres = [];
                            _subGenres = [];
                          });
                        },
                      ),
                      ...widget.segments.map(
                        (segment) => buildChoiceChip(
                          label: segment.name,
                          selected: _segmentId == segment.segmentId,
                          onTap: () async {
                            setState(() {
                              _segmentId = segment.segmentId;
                            });
                            await _loadGenres(segment.segmentId);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Genre',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingGenres)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Wrap(
                      children: [
                        buildChoiceChip(
                          label: 'All',
                          selected: _genreId == null,
                          onTap: () {
                            setState(() {
                              _genreId = null;
                              _subGenreId = null;
                              _subGenres = [];
                            });
                          },
                        ),
                        ..._genres.map(
                          (genre) => buildChoiceChip(
                            label: genre.name,
                            selected: _genreId == genre.genreId,
                            onTap: () async {
                              setState(() {
                                _genreId = genre.genreId;
                              });
                              await _loadSubGenres(genre.genreId);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Subgenre',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingSubGenres)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Wrap(
                      children: [
                        buildChoiceChip(
                          label: 'All',
                          selected: _subGenreId == null,
                          onTap: () {
                            setState(() {
                              _subGenreId = null;
                            });
                          },
                        ),
                        ..._subGenres.map(
                          (subGenre) => buildChoiceChip(
                            label: subGenre.name,
                            selected: _subGenreId == subGenre.subGenreId,
                            onTap: () {
                              setState(() {
                                _subGenreId = subGenre.subGenreId;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, FilterSelection.empty);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          FilterSelection(
                            segmentId: _segmentId,
                            genreId: _genreId,
                            subGenreId: _subGenreId,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}