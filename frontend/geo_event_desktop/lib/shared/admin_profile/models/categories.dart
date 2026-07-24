class AdminSegment {
  const AdminSegment({
    required this.segmentId,
    required this.name,
    required this.color,
    required this.isActive,
    required this.genres,
  });

  final int segmentId;
  final String name;
  final String? color;
  final bool isActive;
  final List<AdminGenre> genres;

  factory AdminSegment.fromJson(Map<String, dynamic> json) {
    return AdminSegment(
      segmentId: json['segmentId'] as int,
      name: (json['name'] ?? '').toString(),
      color: json['color']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      genres: ((json['genres'] as List?) ?? const [])
          .map((e) => AdminGenre.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class AdminGenre {
  const AdminGenre({
    required this.genreId,
    required this.name,
    required this.segmentId,
    required this.segmentName,
    required this.isActive,
    required this.subGenres,
  });

  final int genreId;
  final String name;
  final int segmentId;
  final String? segmentName;
  final bool isActive;
  final List<AdminSubGenre> subGenres;

  factory AdminGenre.fromJson(Map<String, dynamic> json) {
    return AdminGenre(
      genreId: json['genreId'] as int,
      name: (json['name'] ?? '').toString(),
      segmentId: json['segmentId'] as int,
      segmentName: json['segmentName']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      subGenres: ((json['subGenres'] as List?) ?? const [])
          .map((e) => AdminSubGenre.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class AdminSubGenre {
  const AdminSubGenre({
    required this.subGenreId,
    required this.name,
    required this.genreId,
    required this.isActive,
    this.genreName,
    this.segmentId,
    this.segmentName,
  });

  final int subGenreId;
  final String name;
  final int genreId;
  final bool isActive;
  final String? genreName;
  final int? segmentId;
  final String? segmentName;

  factory AdminSubGenre.fromJson(Map<String, dynamic> json) {
    return AdminSubGenre(
      subGenreId: json['subGenreId'] as int,
      name: (json['name'] ?? '').toString(),
      genreId: json['genreId'] as int,
      isActive: json['isActive'] as bool? ?? true,
      genreName: json['genreName']?.toString(),
      segmentId: (json['segmentId'] as num?)?.toInt(),
      segmentName: json['segmentName']?.toString(),
    );
  }
}