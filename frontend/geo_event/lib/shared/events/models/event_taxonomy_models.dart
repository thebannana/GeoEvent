class SegmentItem {
  final int segmentId;
  final String name;
  final String? iconUrl;
  final String? color;
  final bool isActive;

  const SegmentItem({
    required this.segmentId,
    required this.name,
    this.iconUrl,
    this.color,
    required this.isActive,
  });

  factory SegmentItem.fromJson(Map<String, dynamic> json) {
    return SegmentItem(
      segmentId: (json['segmentId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      color: json['color']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class GenreItem {
  final int genreId;
  final String name;
  final int? segmentId;
  final bool isActive;

  const GenreItem({
    required this.genreId,
    required this.name,
    required this.segmentId,
    required this.isActive,
  });

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      genreId: (json['genreId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      segmentId: (json['segmentId'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SubGenreItem {
  final int subGenreId;
  final String name;
  final int? genreId;
  final bool isActive;

  const SubGenreItem({
    required this.subGenreId,
    required this.name,
    required this.genreId,
    required this.isActive,
  });

  factory SubGenreItem.fromJson(Map<String, dynamic> json) {
    return SubGenreItem(
      subGenreId: (json['subGenreId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      genreId: (json['genreId'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}