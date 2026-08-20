import '../../../core/constants/event_status.dart';
import '../../../core/utils/json_helpers.dart';

class EventImageDto {
  final int imageId;
  final String imageUrl;
  final bool isCover;
  final DateTime? uploadedAt;

  const EventImageDto({
    required this.imageId,
    required this.imageUrl,
    required this.isCover,
    required this.uploadedAt,
  });

  factory EventImageDto.fromJson(Map<String, dynamic> json) {
    return EventImageDto(
      imageId: JsonHelpers.asInt(json['imageId'] ?? json['ImageId']) ?? 0,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '').toString().trim(),
      isCover: JsonHelpers.asBool(json['isCover'] ?? json['IsCover']),
      uploadedAt: JsonHelpers.parseDateTime(json['uploadedAt'] ?? json['UploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'imageUrl': imageUrl,
      'isCover': isCover,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}

class MyEventResponseDto {
  final int eventId;
  final int? organizerId;
  final int? segmentId;
  final String? segmentName;
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
  final String? tags;
  final String? accessibilityInfo;
  final String? promoterName;
  final String locale;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final String? coverImageUrl;
  final List<EventImageDto> images;

  const MyEventResponseDto({
    required this.eventId,
    required this.organizerId,
    required this.segmentId,
    required this.segmentName,
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
    required this.tags,
    required this.accessibilityInfo,
    required this.promoterName,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.coverImageUrl,
    required this.images,
  });

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isCompletedByTime {
    final now = DateTime.now().toUtc();
    final localEnd = endDateTime.toUtc();
    return localEnd.isBefore(now) || localEnd.isAtSameMomentAs(now);
  }

  String get displayStatus {
    if (isCompletedByTime) {
      return EventStatus.completed;
    }
    return EventStatus.displayLabel(status);
  }

  bool get canViewReservations {
    return EventStatus.canViewReservations(status);
  }

  factory MyEventResponseDto.fromJson(Map<String, dynamic> json) {
    T? pick<T>(String camel, String pascal) {
      final value = json[camel] ?? json[pascal];
      return value is T ? value : null;
    }

    List<EventImageDto> asImageList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => EventImageDto.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.imageUrl.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final now = DateTime.now().toUtc();
    final images = asImageList(json['images'] ?? json['Images']);

    return MyEventResponseDto(
      eventId: JsonHelpers.asInt(json['eventId'] ?? json['EventId']) ?? 0,
      organizerId: JsonHelpers.asInt(json['organizerId'] ?? json['OrganizerId']),
      segmentId: JsonHelpers.asInt(json['segmentId'] ?? json['SegmentId']),
      segmentName: pick<String>('segmentName', 'SegmentName'),
      genreId: JsonHelpers.asInt(json['genreId'] ?? json['GenreId']),
      genreName: pick<String>('genreName', 'GenreName'),
      subGenreId: JsonHelpers.asInt(json['subGenreId'] ?? json['SubGenreId']),
      subGenreName: pick<String>('subGenreName', 'SubGenreName'),
      title: pick<String>('title', 'Title') ?? '',
      description: pick<String>('description', 'Description') ?? '',
      latitude: JsonHelpers.asDouble(json['latitude'] ?? json['Latitude']),
      longitude: JsonHelpers.asDouble(json['longitude'] ?? json['Longitude']),
      startDateTime: JsonHelpers.parseDateTimeRequired(
          json['startDateTime'] ?? json['StartDateTime'], now),
      endDateTime: JsonHelpers.parseDateTimeRequired(
          json['endDateTime'] ?? json['EndDateTime'], now),
      capacity: JsonHelpers.asInt(json['capacity'] ?? json['Capacity']) ?? 0,
      price: JsonHelpers.asDouble(json['price'] ?? json['Price']),
      status: pick<String>('status', 'Status') ?? '',
      isFeatured: JsonHelpers.asBool(json['isFeatured'] ?? json['IsFeatured']),
      viewCount: JsonHelpers.asInt(json['viewCount'] ?? json['ViewCount']) ?? 0,
      likesCount: JsonHelpers.asInt(json['likesCount'] ?? json['LikesCount']) ?? 0,
      tags: pick<String>('tags', 'Tags'),
      accessibilityInfo: pick<String>('accessibilityInfo', 'AccessibilityInfo'),
      promoterName: pick<String>('promoterName', 'PromoterName'),
      locale: pick<String>('locale', 'Locale') ?? 'bs-BA',
      createdAt: JsonHelpers.parseDateTimeRequired(
          json['createdAt'] ?? json['CreatedAt'], now),
      updatedAt: JsonHelpers.parseDateTime(json['updatedAt'] ?? json['UpdatedAt']),
      imageUrls: JsonHelpers.asStringList(json['imageUrls'] ?? json['ImageUrls']),
      coverImageUrl: pick<String>('coverImageUrl', 'CoverImageUrl'),
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'organizerId': organizerId,
      'segmentId': segmentId,
      'segmentName': segmentName,
      'genreId': genreId,
      'genreName': genreName,
      'subGenreId': subGenreId,
      'subGenreName': subGenreName,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'capacity': capacity,
      'price': price,
      'status': status,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'likesCount': likesCount,
      'tags': tags,
      'accessibilityInfo': accessibilityInfo,
      'promoterName': promoterName,
      'locale': locale,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imageUrls': imageUrls,
      'coverImageUrl': coverImageUrl,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  String? get displayImageUrl {
    if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) {
      return coverImageUrl;
    }
    final cover = images.where((e) => e.isCover).cast<EventImageDto?>().firstWhere(
          (e) => e != null && e.imageUrl.trim().isNotEmpty,
          orElse: () => null,
        );
    if (cover != null) {
      return cover.imageUrl;
    }
    if (imageUrls.isNotEmpty && imageUrls.first.trim().isNotEmpty) {
      return imageUrls.first;
    }
    if (images.isNotEmpty) {
      return images.first.imageUrl;
    }
    return null;
  }
}