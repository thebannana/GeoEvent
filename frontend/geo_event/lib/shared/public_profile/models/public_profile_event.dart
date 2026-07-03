import '../../../core/utils/json_helpers.dart';
import '../../location/data/mapbox_reverse_geocoding_api.dart';

class PublicProfileEvent {
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
  final DateTime? startDateTime;
  final DateTime? endDateTime;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final String? coverImageUrl;
  final String? resolvedLocationName;

  const PublicProfileEvent({
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
    this.resolvedLocationName,
  });

  factory PublicProfileEvent.fromJson(Map<String, dynamic> json) {
    return PublicProfileEvent(
      eventId: JsonHelpers.asInt(json['eventId']) ?? 0,
      organizerId: JsonHelpers.asInt(json['organizerId']),
      segmentId: JsonHelpers.asInt(json['segmentId']),
      segmentName: JsonHelpers.normalize(json['segmentName']),
      genreId: JsonHelpers.asInt(json['genreId']),
      genreName: JsonHelpers.normalize(json['genreName']),
      subGenreId: JsonHelpers.asInt(json['subGenreId']),
      subGenreName: JsonHelpers.normalize(json['subGenreName']),
      title: json['title']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      latitude: JsonHelpers.asDouble(json['latitude']),
      longitude: JsonHelpers.asDouble(json['longitude']),
      startDateTime: JsonHelpers.parseDateTime(json['startDateTime']),
      endDateTime: JsonHelpers.parseDateTime(json['endDateTime']),
      capacity: JsonHelpers.asInt(json['capacity']) ?? 0,
      price: JsonHelpers.asDouble(json['price']),
      status: json['status']?.toString().trim() ?? '',
      isFeatured: JsonHelpers.asBool(json['isFeatured']),
      viewCount: JsonHelpers.asInt(json['viewCount']) ?? 0,
      likesCount: JsonHelpers.asInt(json['likesCount']) ?? 0,
      tags: JsonHelpers.normalize(json['tags']),
      accessibilityInfo: JsonHelpers.normalize(json['accessibilityInfo']),
      promoterName: JsonHelpers.normalize(json['promoterName']),
      locale: JsonHelpers.normalize(json['locale']) ?? 'bs-BA',
      createdAt: JsonHelpers.parseDateTime(json['createdAt']),
      updatedAt: JsonHelpers.parseDateTime(json['updatedAt']),
      imageUrls: JsonHelpers.asStringList(json['imageUrls']),
      coverImageUrl: JsonHelpers.normalize(json['coverImageUrl']),
      resolvedLocationName: JsonHelpers.normalize(
        json['resolvedLocationName'] ??
            json['reverseGeocodedName'] ??
            json['locationName'] ??
            json['address'],
      ),
    );
  }

  String? get primaryImage {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return coverImageUrl;
    }
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  Future<String> getLocationLabel(
    MapboxReverseGeocodingApi reverseGeocodingApi,
  ) async {
    if (resolvedLocationName != null && resolvedLocationName!.trim().isNotEmpty) {
      return resolvedLocationName!.trim();
    }

    try {
      final place = await reverseGeocodingApi.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      final subtitle = place?.subtitle?.trim();
      if (subtitle != null && subtitle.isNotEmpty) {
        return subtitle;
      }

      final title = place?.title.trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    } catch (_) {}

    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}