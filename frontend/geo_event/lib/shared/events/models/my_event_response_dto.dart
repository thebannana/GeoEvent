class MyEventResponseDto {
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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final String? coverImageUrl;

  const MyEventResponseDto({
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

  factory MyEventResponseDto.fromJson(Map<String, dynamic> json) {
    T? pick<T>(String camel, String pascal) {
      final value = json[camel] ?? json[pascal];
      return value is T ? value : null;
    }

    int? asInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double asDouble(dynamic value, [double fallback = 0]) {
      if (value == null) return fallback;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? fallback;
    }

    bool asBool(dynamic value, [bool fallback = false]) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
      return fallback;
    }

    DateTime asDateTime(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? fallback;
    }

    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    final now = DateTime.now();

    return MyEventResponseDto(
      eventId: asInt(json['eventId'] ?? json['EventId']) ?? 0,
      organizerId: asInt(json['organizerId'] ?? json['OrganizerId']),
      segmentId: asInt(json['segmentId'] ?? json['SegmentId']),
      segmentName: pick<String>('segmentName', 'SegmentName'),
      genreId: asInt(json['genreId'] ?? json['GenreId']),
      genreName: pick<String>('genreName', 'GenreName'),
      subGenreId: asInt(json['subGenreId'] ?? json['SubGenreId']),
      subGenreName: pick<String>('subGenreName', 'SubGenreName'),
      venueId: asInt(json['venueId'] ?? json['VenueId']),
      venueName: pick<String>('venueName', 'VenueName'),
      cityId: asInt(json['cityId'] ?? json['CityId']),
      title: pick<String>('title', 'Title') ?? '',
      description: pick<String>('description', 'Description') ?? '',
      latitude: asDouble(json['latitude'] ?? json['Latitude']),
      longitude: asDouble(json['longitude'] ?? json['Longitude']),
      startDateTime: asDateTime(
        json['startDateTime'] ?? json['StartDateTime'],
        now,
      ),
      endDateTime: asDateTime(
        json['endDateTime'] ?? json['EndDateTime'],
        now,
      ),
      capacity: asInt(json['capacity'] ?? json['Capacity']) ?? 0,
      price: asDouble(json['price'] ?? json['Price']),
      status: pick<String>('status', 'Status') ?? '',
      isOnline: asBool(json['isOnline'] ?? json['IsOnline']),
      isFeatured: asBool(json['isFeatured'] ?? json['IsFeatured']),
      viewCount: asInt(json['viewCount'] ?? json['ViewCount']) ?? 0,
      likesCount: asInt(json['likesCount'] ?? json['LikesCount']) ?? 0,
      tags: pick<String>('tags', 'Tags'),
      externalUrl: pick<String>('externalUrl', 'ExternalUrl'),
      accessibilityInfo:
          pick<String>('accessibilityInfo', 'AccessibilityInfo'),
      promoterName: pick<String>('promoterName', 'PromoterName'),
      locale: pick<String>('locale', 'Locale') ?? 'bs-BA',
      createdAt: asDateTime(
        json['createdAt'] ?? json['CreatedAt'],
        now,
      ),
      updatedAt: (json['updatedAt'] ?? json['UpdatedAt']) != null
          ? asDateTime(json['updatedAt'] ?? json['UpdatedAt'], now)
          : null,
      imageUrls: asStringList(json['imageUrls'] ?? json['ImageUrls']),
      coverImageUrl: pick<String>('coverImageUrl', 'CoverImageUrl'),
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
      'venueId': venueId,
      'venueName': venueName,
      'cityId': cityId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'capacity': capacity,
      'price': price,
      'status': status,
      'isOnline': isOnline,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'likesCount': likesCount,
      'tags': tags,
      'externalUrl': externalUrl,
      'accessibilityInfo': accessibilityInfo,
      'promoterName': promoterName,
      'locale': locale,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imageUrls': imageUrls,
      'coverImageUrl': coverImageUrl,
    };
  }

  String? get displayImageUrl {
    if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) {
      return coverImageUrl;
    }
    if (imageUrls.isNotEmpty && imageUrls.first.trim().isNotEmpty) {
      return imageUrls.first;
    }
    return null;
  }
}