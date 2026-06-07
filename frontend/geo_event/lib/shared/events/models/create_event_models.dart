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
  final bool isLiked;
  final bool isBookmarked;
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
    this.isLiked = false,
    this.isBookmarked = false,
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

  bool readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return fallback;
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
    isOnline: readBool(json['isOnline']),
    isFeatured: readBool(json['isFeatured']),
    viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
    isLiked: readBool(json['isLiked']),
    isBookmarked: readBool(json['isBookmarked']),
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

  EventItem copyWith({
    int? eventId,
    int? organizerId,
    int? segmentId,
    String? segmentName,
    int? genreId,
    String? genreName,
    int? subGenreId,
    String? subGenreName,
    int? venueId,
    String? venueName,
    int? cityId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? capacity,
    double? price,
    String? status,
    bool? isOnline,
    bool? isFeatured,
    int? viewCount,
    int? likesCount,
    bool? isLiked,
    bool? isBookmarked,
    String? tags,
    String? externalUrl,
    String? accessibilityInfo,
    String? promoterName,
    String? locale,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    String? coverImageUrl,
  }) {
    return EventItem(
      eventId: eventId ?? this.eventId,
      organizerId: organizerId ?? this.organizerId,
      segmentId: segmentId ?? this.segmentId,
      segmentName: segmentName ?? this.segmentName,
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
      subGenreId: subGenreId ?? this.subGenreId,
      subGenreName: subGenreName ?? this.subGenreName,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      cityId: cityId ?? this.cityId,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      tags: tags ?? this.tags,
      externalUrl: externalUrl ?? this.externalUrl,
      accessibilityInfo: accessibilityInfo ?? this.accessibilityInfo,
      promoterName: promoterName ?? this.promoterName,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
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