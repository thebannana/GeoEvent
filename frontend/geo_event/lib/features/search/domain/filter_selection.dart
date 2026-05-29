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

  static const empty = FilterSelection();
}