class FilterSelection {
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;

  const FilterSelection({
    this.segmentId,
    this.genreId,
    this.subGenreId,
  });

  bool get hasActive =>
      segmentId != null || genreId != null || subGenreId != null;

  FilterSelection copyWith({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    bool clearSegment = false,
    bool clearGenre = false,
    bool clearSubGenre = false,
  }) {
    return FilterSelection(
      segmentId: clearSegment ? null : (segmentId ?? this.segmentId),
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      subGenreId: clearSubGenre ? null : (subGenreId ?? this.subGenreId),
    );
  }

  static const empty = FilterSelection();
}