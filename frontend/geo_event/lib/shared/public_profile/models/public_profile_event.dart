class PublicProfileEvent {
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
  final DateTime? startDateTime;
  final DateTime? endDateTime;
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

  const PublicProfileEvent({
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

  factory PublicProfileEvent.fromJson(Map<String, dynamic> json) {
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

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PublicProfileEvent(
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
      startDateTime: parseNullableDate(json['startDateTime']),
      endDateTime: parseNullableDate(json['endDateTime']),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      isOnline: readBool(json['isOnline']),
      isFeatured: readBool(json['isFeatured']),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      tags: json['tags']?.toString(),
      externalUrl: json['externalUrl']?.toString(),
      accessibilityInfo: json['accessibilityInfo']?.toString(),
      promoterName: json['promoterName']?.toString(),
      locale: json['locale']?.toString() ?? 'bs-BA',
      createdAt: parseNullableDate(json['createdAt']),
      updatedAt: parseNullableDate(json['updatedAt']),
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      coverImageUrl: json['coverImageUrl']?.toString(),
    );
  }

  String? get primaryImage {
    if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) {
      return coverImageUrl;
    }
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  String? get locationLabel {
    if (isOnline) return 'Online';
    if (venueName != null && venueName!.trim().isNotEmpty) return venueName;
    return null;
  }
}