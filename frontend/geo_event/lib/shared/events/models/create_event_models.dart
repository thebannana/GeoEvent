import 'dart:typed_data';

class MapboxPlace {
  final String id;
  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;

  const MapboxPlace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}

class SegmentItem {
  final int segmentId;
  final String name;
  final String? iconUrl;
  final String? color;

  const SegmentItem({
    required this.segmentId,
    required this.name,
    this.iconUrl,
    this.color,
  });

  factory SegmentItem.fromJson(Map<String, dynamic> json) {
    return SegmentItem(
      segmentId: (json['segmentId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

class GenreItem {
  final int genreId;
  final String name;

  const GenreItem({
    required this.genreId,
    required this.name,
  });

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      genreId: (json['genreId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class SubGenreItem {
  final int subGenreId;
  final String name;

  const SubGenreItem({
    required this.subGenreId,
    required this.name,
  });

  factory SubGenreItem.fromJson(Map<String, dynamic> json) {
    return SubGenreItem(
      subGenreId: (json['subGenreId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class EventItem {
  final int eventId;
  final int? organizerId;
  final int? segmentId;
  final String? segmentName;
  final int? genreId;
  final String? genreName;
  final int? subGenreId;
  final String? subGenreName;
  final int? venueId;
  final String? venueName;
  final int? cityId;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final double price;
  final String status;
  final bool isOnline;
  final bool isFeatured;
  final int viewCount;
  final int likesCount;
  final String? tags;
  final String? externalUrl;
  final String? accessibilityInfo;
  final String? promoterName;
  final String locale;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final String? coverImageUrl;

  const EventItem({
    required this.eventId,
    required this.organizerId,
    required this.segmentId,
    required this.segmentName,
    required this.genreId,
    required this.genreName,
    required this.subGenreId,
    required this.subGenreName,
    required this.venueId,
    required this.venueName,
    required this.cityId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.price,
    required this.status,
    required this.isOnline,
    required this.isFeatured,
    required this.viewCount,
    required this.likesCount,
    required this.tags,
    required this.externalUrl,
    required this.accessibilityInfo,
    required this.promoterName,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.coverImageUrl,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value == null) {
        return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.tryParse(value.toString()) ??
          fallback ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return EventItem(
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      organizerId: (json['organizerId'] as num?)?.toInt(),
      segmentId: (json['segmentId'] as num?)?.toInt(),
      segmentName: json['segmentName']?.toString(),
      genreId: (json['genreId'] as num?)?.toInt(),
      genreName: json['genreName']?.toString(),
      subGenreId: (json['subGenreId'] as num?)?.toInt(),
      subGenreName: json['subGenreName']?.toString(),
      venueId: (json['venueId'] as num?)?.toInt(),
      venueName: json['venueName']?.toString(),
      cityId: (json['cityId'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      startDateTime: parseDate(json['startDateTime']),
      endDateTime: parseDate(
        json['endDateTime'],
        fallback: parseDate(json['startDateTime']),
      ),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'Draft',
      isOnline: json['isOnline'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      tags: json['tags']?.toString(),
      externalUrl: json['externalUrl']?.toString(),
      accessibilityInfo: json['accessibilityInfo']?.toString(),
      promoterName: json['promoterName']?.toString(),
      locale: json['locale']?.toString() ?? 'bs-BA',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      coverImageUrl: json['coverImageUrl']?.toString(),
    );
  }
}

class CreateEventResponse {
  final int eventId;
  final List<String> imageUrls;
  final String? coverImageUrl;

  const CreateEventResponse({
    required this.eventId,
    required this.imageUrls,
    required this.coverImageUrl,
  });

  factory CreateEventResponse.fromJson(Map<String, dynamic> json) {
    return CreateEventResponse(
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      coverImageUrl: json['coverImageUrl']?.toString(),
    );
  }
}

class EventImageRequest {
  final String imageUrl;
  final bool isCover;

  const EventImageRequest({
    required this.imageUrl,
    this.isCover = false,
  });

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'isCover': isCover,
      };
}

class EventImageUploadItem {
  final String localPath;
  final bool isCover;
  final Uint8List? previewBytes;

  const EventImageUploadItem({
    required this.localPath,
    this.isCover = false,
    this.previewBytes,
  });

  String get fileName {
    final normalized = localPath.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty && parts.last.isNotEmpty
        ? parts.last
        : 'image.jpg';
  }

  EventImageUploadItem copyWith({
    String? localPath,
    bool? isCover,
    Uint8List? previewBytes,
    bool clearPreviewBytes = false,
  }) {
    return EventImageUploadItem(
      localPath: localPath ?? this.localPath,
      isCover: isCover ?? this.isCover,
      previewBytes: clearPreviewBytes
          ? null
          : (previewBytes ?? this.previewBytes),
    );
  }
}

class CreateEventRequest {
  final String title;
  final String description;
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;
  final int? venueId;
  final int? cityId;
  final double latitude;
  final double longitude;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final double price;
  final bool isOnline;
  final String? tags;
  final String? externalUrl;
  final String? accessibilityInfo;
  final String? promoterName;
  final String locale;

  const CreateEventRequest({
    required this.title,
    required this.description,
    required this.segmentId,
    required this.genreId,
    required this.subGenreId,
    required this.venueId,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.price,
    required this.isOnline,
    this.tags,
    this.externalUrl,
    this.accessibilityInfo,
    this.promoterName,
    required this.locale,
  });

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'segmentId': segmentId,
        'genreId': genreId,
        'subGenreId': subGenreId,
        'venueId': venueId,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'capacity': capacity,
        'price': price,
        'isOnline': isOnline,
        'tags': _cleanNullable(tags),
        'externalUrl': _cleanNullable(externalUrl),
        'accessibilityInfo': _cleanNullable(accessibilityInfo),
        'promoterName': _cleanNullable(promoterName),
        'locale': locale.trim().isEmpty ? 'bs-BA' : locale.trim(),
      };

  String? _cleanNullable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
    }
}