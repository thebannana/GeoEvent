import 'package:flutter/foundation.dart';

@immutable
class MapFilterSelection {
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;
  final double radiusKm;
  final bool freeOnly;
  final bool todayOnly;
  final bool usePreferences;
  final bool showGlobalEvents;
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
    this.showGlobalEvents = false,
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
    bool? showGlobalEvents,
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
      showGlobalEvents: showGlobalEvents ?? this.showGlobalEvents,
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
      showGlobalEvents ||
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
        other.showGlobalEvents == showGlobalEvents &&
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
        showGlobalEvents,
        minPrice,
        maxPrice,
      );
}