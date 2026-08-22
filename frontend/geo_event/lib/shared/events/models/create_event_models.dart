import 'dart:typed_data';

import '../../../core/constants/event_status.dart';
import '../../../core/utils/json_helpers.dart';

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
  final String? segmentColor;
  final int? genreId;
  final String? genreName;
  final int? subGenreId;
  final String? subGenreName;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final double price;
  final String status;
  final bool isFeatured;
  final int viewCount;
  final int likesCount;
  final bool isLiked;
  final bool isBookmarked;
  final double recommendationScore;
  final String? tags;
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
    required this.segmentColor,
    required this.genreId,
    required this.genreName,
    required this.subGenreId,
    required this.subGenreName,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.price,
    required this.status,
    required this.isFeatured,
    required this.viewCount,
    required this.likesCount,
    required this.recommendationScore,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.tags,
    required this.accessibilityInfo,
    required this.promoterName,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.coverImageUrl,
  });

  String get normalizedStatus =>
      status.trim().toLowerCase();

  bool get isCancelled =>
      normalizedStatus == 'cancelled';

  bool get isFinished {
    final now = DateTime.now().toUtc();
    final end = endDateTime.toUtc();

    return end.isBefore(now) ||
        end.isAtSameMomentAs(now);
  }

  bool get isUpcoming =>
      startDateTime
          .toUtc()
          .isAfter(DateTime.now().toUtc());

  bool get isOngoing {
    final now = DateTime.now().toUtc();
    final start = startDateTime.toUtc();
    final end = endDateTime.toUtc();

    final started = start.isBefore(now) ||
        start.isAtSameMomentAs(now);

    return started && end.isAfter(now);
  }

  bool get isVisibleInSearch =>
      !isCancelled && !isFinished;

  factory EventItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final defaultDate =
        DateTime.fromMillisecondsSinceEpoch(
      0,
      isUtc: true,
    );

    final startDate =
        JsonHelpers.parseDateTimeRequired(
      json['startDateTime'],
      defaultDate,
    );

    return EventItem(
      eventId: JsonHelpers.asInt(
            json['eventId'],
          ) ??
          0,
      organizerId: JsonHelpers.asInt(
        json['organizerId'],
      ),
      segmentId: JsonHelpers.asInt(
        json['segmentId'],
      ),
      segmentName: json['segmentName']?.toString(),
      segmentColor: json['segmentColor']?.toString(),
      genreId: JsonHelpers.asInt(
        json['genreId'],
      ),
      genreName: json['genreName']?.toString(),
      subGenreId: JsonHelpers.asInt(
        json['subGenreId'],
      ),
      subGenreName:
          json['subGenreName']?.toString(),
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      latitude: JsonHelpers.asDouble(
        json['latitude'],
      ),
      longitude: JsonHelpers.asDouble(
        json['longitude'],
      ),
      startDateTime: startDate,
      endDateTime:
          JsonHelpers.parseDateTimeRequired(
        json['endDateTime'],
        startDate,
      ),
      capacity: JsonHelpers.asInt(
            json['capacity'],
          ) ??
          0,
      price: JsonHelpers.asDouble(
        json['price'],
      ),
      status: json['status']?.toString() ??
          EventStatus.pending,
      isFeatured: JsonHelpers.asBool(
        json['isFeatured'],
      ),
      viewCount: JsonHelpers.asInt(
            json['viewCount'],
          ) ??
          0,
      likesCount: JsonHelpers.asInt(
            json['likesCount'],
          ) ??
          0,
      recommendationScore:
          JsonHelpers.asDouble(
            json['recommendationScore'],
          ),
      isLiked: JsonHelpers.asBool(
        json['isLiked'],
      ),
      isBookmarked: JsonHelpers.asBool(
        json['isBookmarked'],
      ),
      tags: json['tags']?.toString(),
      accessibilityInfo:
          json['accessibilityInfo']?.toString(),
      promoterName:
          json['promoterName']?.toString(),
      locale: json['locale']?.toString() ??
          'bs-BA',
      createdAt: JsonHelpers.parseDateTime(
        json['createdAt'],
      ),
      updatedAt: JsonHelpers.parseDateTime(
        json['updatedAt'],
      ),
      imageUrls: JsonHelpers.asStringList(
        json['imageUrls'],
      ),
      coverImageUrl:
          json['coverImageUrl']?.toString(),
    );
  }

  EventItem copyWith({
    int? eventId,
    int? organizerId,
    int? segmentId,
    String? segmentName,
    String? segmentColor,
    int? genreId,
    String? genreName,
    int? subGenreId,
    String? subGenreName,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? capacity,
    double? price,
    String? status,
    bool? isFeatured,
    int? viewCount,
    int? likesCount,
    double? recommendationScore,
    bool? isLiked,
    bool? isBookmarked,
    String? tags,
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
      organizerId:
          organizerId ?? this.organizerId,
      segmentId: segmentId ?? this.segmentId,
      segmentName:
          segmentName ?? this.segmentName,
      segmentColor:
          segmentColor ?? this.segmentColor,
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
      subGenreId:
          subGenreId ?? this.subGenreId,
      subGenreName:
          subGenreName ?? this.subGenreName,
      title: title ?? this.title,
      description:
          description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDateTime:
          startDateTime ?? this.startDateTime,
      endDateTime:
          endDateTime ?? this.endDateTime,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      status: status ?? this.status,
      isFeatured:
          isFeatured ?? this.isFeatured,
      viewCount:
          viewCount ?? this.viewCount,
      likesCount:
          likesCount ?? this.likesCount,
      recommendationScore:
          recommendationScore ??
              this.recommendationScore,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked:
          isBookmarked ?? this.isBookmarked,
      tags: tags ?? this.tags,
      accessibilityInfo:
          accessibilityInfo ??
              this.accessibilityInfo,
      promoterName:
          promoterName ?? this.promoterName,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls:
          imageUrls ?? this.imageUrls,
      coverImageUrl:
          coverImageUrl ?? this.coverImageUrl,
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

  factory CreateEventResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateEventResponse(
      eventId: JsonHelpers.asInt(
            json['eventId'],
          ) ??
          0,
      imageUrls: JsonHelpers.asStringList(
        json['imageUrls'],
      ),
      coverImageUrl:
          json['coverImageUrl']?.toString(),
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

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'isCover': isCover,
    };
  }
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
    final normalized =
        localPath.replaceAll('\\', '/');

    final parts = normalized.split('/');

    return parts.isNotEmpty &&
            parts.last.isNotEmpty
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
      localPath:
          localPath ?? this.localPath,
      isCover: isCover ?? this.isCover,
      previewBytes: clearPreviewBytes
          ? null
          : previewBytes ?? this.previewBytes,
    );
  }
}

class CreateEventRequest {
  final String title;
  final String description;
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;
  final double latitude;
  final double longitude;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final double price;
  final String? tags;
  final String? accessibilityInfo;
  final String? promoterName;
  final String locale;

  const CreateEventRequest({
    required this.title,
    required this.description,
    required this.segmentId,
    required this.genreId,
    required this.subGenreId,
    required this.latitude,
    required this.longitude,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.price,
    this.tags,
    this.accessibilityInfo,
    this.promoterName,
    required this.locale,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'segmentId': segmentId,
      'genreId': genreId,
      'subGenreId': subGenreId,
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime':
          startDateTime.toUtc().toIso8601String(),
      'endDateTime':
          endDateTime.toUtc().toIso8601String(),
      'capacity': capacity,
      'price': price,
      'tags': _cleanNullable(tags),
      'accessibilityInfo':
          _cleanNullable(accessibilityInfo),
      'promoterName':
          _cleanNullable(promoterName),
      'locale': locale.trim().isEmpty
          ? 'bs-BA'
          : locale.trim(),
    };
  }

  String? _cleanNullable(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}