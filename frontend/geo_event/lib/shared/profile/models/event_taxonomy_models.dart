class SegmentLookup {
  final int segmentId;
  final String name;
  final String? iconUrl;
  final String? color;
  final bool isActive;
  final List<GenreLookup> genres;

  const SegmentLookup({
    required this.segmentId,
    required this.name,
    this.iconUrl,
    this.color,
    required this.isActive,
    required this.genres,
  });

  factory SegmentLookup.fromJson(Map<String, dynamic> json) {
    return SegmentLookup(
      segmentId: (json['segmentId'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      iconUrl: _normalizeNullableString(json['iconUrl']),
      color: _normalizeNullableString(json['color']),
      isActive: json['isActive'] as bool? ?? true,
      genres: ((json['genres'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => GenreLookup.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}

class GenreLookup {
  final int genreId;
  final String name;
  final int? segmentId;
  final String? segmentName;
  final bool isActive;
  final List<SubGenreLookup> subGenres;

  const GenreLookup({
    required this.genreId,
    required this.name,
    this.segmentId,
    this.segmentName,
    required this.isActive,
    required this.subGenres,
  });

  factory GenreLookup.fromJson(Map<String, dynamic> json) {
    return GenreLookup(
      genreId: (json['genreId'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      segmentId: (json['segmentId'] as num?)?.toInt(),
      segmentName: SegmentLookup._normalizeNullableString(json['segmentName']),
      isActive: json['isActive'] as bool? ?? true,
      subGenres: ((json['subGenres'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => SubGenreLookup.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class SubGenreLookup {
  final int subGenreId;
  final String name;
  final int? genreId;
  final bool isActive;

  const SubGenreLookup({
    required this.subGenreId,
    required this.name,
    this.genreId,
    required this.isActive,
  });

  factory SubGenreLookup.fromJson(Map<String, dynamic> json) {
    return SubGenreLookup(
      subGenreId: (json['subGenreId'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      genreId: (json['genreId'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}