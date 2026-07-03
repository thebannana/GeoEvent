class PreferencesScreenState {
  const PreferencesScreenState({
    required this.segmentItems,
    required this.genreItems,
    required this.subGenreItems,
  });

  final List<PreferenceItemViewModel> segmentItems;
  final List<PreferenceItemViewModel> genreItems;
  final List<PreferenceItemViewModel> subGenreItems;

  bool get isEmpty =>
      segmentItems.isEmpty && genreItems.isEmpty && subGenreItems.isEmpty;
}

class PreferenceItemViewModel {
  const PreferenceItemViewModel({
    required this.prefId,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.progress,
    required this.lastUpdated,
    required this.type,
  });

  final int prefId;
  final String title;
  final String? subtitle;
  final double score;
  final double progress;
  final DateTime lastUpdated;
  final PreferenceItemType type;
}

enum PreferenceItemType {
  segment,
  genre,
  subGenre,
}