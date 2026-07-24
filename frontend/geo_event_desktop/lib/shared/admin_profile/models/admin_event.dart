enum AdminEventViewStyle { list, grid2, grid3 }

enum AdminEventStatusFilter { all, pending, confirmed, cancelled, completed }

enum AdminEventSortField {
  startDateTime,
  createdAt,
  title,
  views,
  likes,
}

class EventImageResponse {
  final int imageId;
  final String imageUrl;
  final bool isCover;
  final DateTime? uploadedAt;

  const EventImageResponse({
    required this.imageId,
    required this.imageUrl,
    required this.isCover,
    required this.uploadedAt,
  });

  factory EventImageResponse.fromJson(Map<String, dynamic> json) {
    final imageIdRaw = json['imageId'] ?? json['ImageId'] ?? 0;
    final isCoverRaw = json['isCover'] ?? json['IsCover'] ?? false;
    final uploadedAtRaw = json['uploadedAt'] ?? json['UploadedAt'];

    return EventImageResponse(
      imageId: (imageIdRaw as num?)?.toInt() ?? 0,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '')
          .toString()
          .trim(),
      isCover: _parseBool(isCoverRaw),
      uploadedAt: _parseDateTime(uploadedAtRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'imageUrl': imageUrl,
      'isCover': isCover,
      'uploadedAt': uploadedAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }
}

class AdminEvent {
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
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final int capacity;
  final double price;
  final String status;
  final bool isFeatured;
  final int viewCount;
  final int likesCount;
  final bool isLiked;
  final String? tags;
  final String? accessibilityInfo;
  final String? promoterName;
  final String locale;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final String? coverImageUrl;
  final List<EventImageResponse> images;

  const AdminEvent({
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
    required this.isLiked,
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

  String get displayTitle {
    final value = title.trim();
    return value.isEmpty ? 'Untitled event' : value;
  }

  String get displayDescription {
    final value = description.trim();
    return value.isEmpty ? 'No description' : value;
  }

  String get displayPromoterName {
    final value = promoterName?.trim();
    return value == null || value.isEmpty ? 'No promoter' : value;
  }

  String get displayStatus {
    final value = status.trim();
    return value.isEmpty ? 'Unknown' : value;
  }

  bool get hasCoverImage {
    final value = coverImageUrl?.trim();
    return value != null && value.isNotEmpty;
  }

  String? get displayImageUrl {
    final cover = coverImageUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;

    for (final image in images) {
      final normalized = image.imageUrl.trim();
      if (normalized.isNotEmpty) return normalized;
    }

    for (final image in imageUrls) {
      final normalized = image.trim();
      if (normalized.isNotEmpty) return normalized;
    }

    return null;
  }

  String get category {
    return subGenreName ?? genreName ?? segmentName ?? 'Event';
  }

  String get displayTitleWithSegment {
    final segment = segmentName?.trim();
    if (segment == null || segment.isEmpty) return displayTitle;
    return '$segment: $displayTitle';
  }

  String get genreSubtitle {
    final values = <String>[
      if ((genreName ?? '').trim().isNotEmpty) genreName!.trim(),
      if ((subGenreName ?? '').trim().isNotEmpty) subGenreName!.trim(),
    ];
    return values.join(' • ');
  }

  bool get hasGenreSubtitle => genreSubtitle.isNotEmpty;

  String get locationLabel {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String get dateLabel {
    final value = startDateTime;
    if (value == null) return 'No date';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month - 1]} ${value.year} • $hh:$mm';
  }

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    final eventIdRaw = json['eventId'] ?? json['EventId'] ?? 0;
    final organizerIdRaw = json['organizerId'] ?? json['OrganizerId'];
    final segmentIdRaw = json['segmentId'] ?? json['SegmentId'];
    final genreIdRaw = json['genreId'] ?? json['GenreId'];
    final subGenreIdRaw = json['subGenreId'] ?? json['SubGenreId'];
    final capacityRaw = json['capacity'] ?? json['Capacity'] ?? 0;
    final priceRaw = json['price'] ?? json['Price'] ?? 0;
    final latitudeRaw = json['latitude'] ?? json['Latitude'] ?? 0;
    final longitudeRaw = json['longitude'] ?? json['Longitude'] ?? 0;
    final featuredRaw = json['isFeatured'] ?? json['IsFeatured'] ?? false;
    final viewCountRaw = json['viewCount'] ?? json['ViewCount'] ?? 0;
    final likesCountRaw = json['likesCount'] ?? json['LikesCount'] ?? 0;
    final isLikedRaw = json['isLiked'] ?? json['IsLiked'] ?? false;
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final updatedAtRaw = json['updatedAt'] ?? json['UpdatedAt'];
    final startDateTimeRaw = json['startDateTime'] ?? json['StartDateTime'];
    final endDateTimeRaw = json['endDateTime'] ?? json['EndDateTime'];

    final rawImages = json['images'] ?? json['Images'];
    final images = rawImages is List
        ? rawImages
            .whereType<Map>()
            .map((e) => EventImageResponse.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.imageUrl.trim().isNotEmpty)
            .toList(growable: false)
        : <EventImageResponse>[];

    final rawImageUrls = json['imageUrls'] ?? json['ImageUrls'];
    final parsedImageUrls = rawImageUrls is List
        ? rawImageUrls
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : <String>[];

    final derivedImageUrls = images
        .map((e) => e.imageUrl.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final mergedImageUrls = <String>[
      ...parsedImageUrls,
      ...derivedImageUrls.where(
        (url) => !parsedImageUrls.any((existing) => existing == url),
      ),
    ];

    final rawCoverImageUrl = _normalizeNullableString(
      json['coverImageUrl'] ?? json['CoverImageUrl'],
    );

    final derivedCoverImageUrl = images
        .where((e) => e.isCover && e.imageUrl.trim().isNotEmpty)
        .map((e) => e.imageUrl.trim())
        .cast<String?>()
        .firstWhere(
          (e) => e != null && e.isNotEmpty,
          orElse: () => null,
        );

    return AdminEvent(
      eventId: (eventIdRaw as num?)?.toInt() ?? 0,
      organizerId: (organizerIdRaw as num?)?.toInt(),
      segmentId: (segmentIdRaw as num?)?.toInt(),
      segmentName: _normalizeNullableString(
        json['segmentName'] ?? json['SegmentName'],
      ),
      segmentColor: _normalizeNullableString(
        json['segmentColor'] ?? json['SegmentColor'],
      ),
      genreId: (genreIdRaw as num?)?.toInt(),
      genreName: _normalizeNullableString(
        json['genreName'] ?? json['GenreName'],
      ),
      subGenreId: (subGenreIdRaw as num?)?.toInt(),
      subGenreName: _normalizeNullableString(
        json['subGenreName'] ?? json['SubGenreName'],
      ),
      title: (json['title'] ?? json['Title'] ?? '').toString().trim(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString()
          .trim(),
      latitude: (latitudeRaw as num?)?.toDouble() ?? 0,
      longitude: (longitudeRaw as num?)?.toDouble() ?? 0,
      startDateTime: _parseDateTime(startDateTimeRaw),
      endDateTime: _parseDateTime(endDateTimeRaw),
      capacity: (capacityRaw as num?)?.toInt() ?? 0,
      price: (priceRaw as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? json['Status'] ?? '').toString().trim(),
      isFeatured: _parseBool(featuredRaw),
      viewCount: (viewCountRaw as num?)?.toInt() ?? 0,
      likesCount: (likesCountRaw as num?)?.toInt() ?? 0,
      isLiked: _parseBool(isLikedRaw),
      tags: _normalizeNullableString(json['tags'] ?? json['Tags']),
      accessibilityInfo: _normalizeNullableString(
        json['accessibilityInfo'] ?? json['AccessibilityInfo'],
      ),
      promoterName: _normalizeNullableString(
        json['promoterName'] ?? json['PromoterName'],
      ),
      locale: (json['locale'] ?? json['Locale'] ?? 'bs-BA').toString().trim(),
      createdAt: _parseDateTime(createdAtRaw),
      updatedAt: _parseDateTime(updatedAtRaw),
      imageUrls: mergedImageUrls,
      coverImageUrl: rawCoverImageUrl ?? derivedCoverImageUrl,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'organizerId': organizerId,
      'segmentId': segmentId,
      'segmentName': segmentName,
      'segmentColor': segmentColor,
      'genreId': genreId,
      'genreName': genreName,
      'subGenreId': subGenreId,
      'subGenreName': subGenreName,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime': startDateTime?.toUtc().toIso8601String(),
      'endDateTime': endDateTime?.toUtc().toIso8601String(),
      'capacity': capacity,
      'price': price,
      'status': status,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'tags': tags,
      'accessibilityInfo': accessibilityInfo,
      'promoterName': promoterName,
      'locale': locale,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'imageUrls': imageUrls,
      'coverImageUrl': coverImageUrl,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  AdminEvent copyWith({
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
    bool? isLiked,
    String? tags,
    String? accessibilityInfo,
    String? promoterName,
    String? locale,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    String? coverImageUrl,
    List<EventImageResponse>? images,
    bool clearTags = false,
    bool clearAccessibilityInfo = false,
    bool clearPromoterName = false,
    bool clearCoverImageUrl = false,
  }) {
    return AdminEvent(
      eventId: eventId ?? this.eventId,
      organizerId: organizerId ?? this.organizerId,
      segmentId: segmentId ?? this.segmentId,
      segmentName: segmentName ?? this.segmentName,
      segmentColor: segmentColor ?? this.segmentColor,
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
      subGenreId: subGenreId ?? this.subGenreId,
      subGenreName: subGenreName ?? this.subGenreName,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      tags: clearTags ? null : tags ?? this.tags,
      accessibilityInfo: clearAccessibilityInfo
          ? null
          : accessibilityInfo ?? this.accessibilityInfo,
      promoterName:
          clearPromoterName ? null : promoterName ?? this.promoterName,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      coverImageUrl:
          clearCoverImageUrl ? null : coverImageUrl ?? this.coverImageUrl,
      images: images ?? this.images,
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }
}

class EventReservationSummary {
  const EventReservationSummary({
    required this.eventId,
    required this.capacity,
    required this.reservedCount,
    required this.confirmedCount,
    required this.pendingCount,
    required this.availableCount,
    required this.reservationCount,
    required this.isSoldOut,
  });

  final int eventId;
  final int capacity;
  final int reservedCount;
  final int confirmedCount;
  final int pendingCount;
  final int availableCount;
  final int reservationCount;
  final bool isSoldOut;

  double get progress {
    if (capacity <= 0) return 0;
    return (reservedCount / capacity).clamp(0, 1).toDouble();
  }

  String get occupancyLabel {
    if (capacity <= 0) return '$reservedCount reserved';
    return '$reservedCount/$capacity';
  }

  factory EventReservationSummary.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => (value as num?)?.toInt() ?? 0;

    return EventReservationSummary(
      eventId: toInt(json['eventId'] ?? json['EventId']),
      capacity: toInt(json['capacity'] ?? json['Capacity']),
      reservedCount: toInt(json['reservedCount'] ?? json['ReservedCount']),
      confirmedCount: toInt(json['confirmedCount'] ?? json['ConfirmedCount']),
      pendingCount: toInt(json['pendingCount'] ?? json['PendingCount']),
      availableCount: toInt(json['availableCount'] ?? json['AvailableCount']),
      reservationCount:
          toInt(json['reservationCount'] ?? json['ReservationCount']),
      isSoldOut: _parseBool(json['isSoldOut'] ?? json['IsSoldOut'] ?? false),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }
}

class ManageableEventAttendeePreview {
  const ManageableEventAttendeePreview({
    required this.reservationId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.quantity,
  });

  final int reservationId;
  final int userId;
  final String username;
  final String? avatarUrl;
  final int quantity;

  String get displayUsername {
    final value = username.trim();
    return value.isEmpty ? 'Unknown user' : value;
  }

  factory ManageableEventAttendeePreview.fromJson(Map<String, dynamic> json) {
    return ManageableEventAttendeePreview(
      reservationId: ((json['reservationId'] ?? json['ReservationId']) as num?)
              ?.toInt() ??
          0,
      userId: ((json['userId'] ?? json['UserId']) as num?)?.toInt() ?? 0,
      username: (json['username'] ?? json['Username'] ?? '')
          .toString()
          .trim(),
      avatarUrl:
          _normalizeNullableString(json['avatarUrl'] ?? json['AvatarUrl']),
      quantity: ((json['quantity'] ?? json['Quantity']) as num?)?.toInt() ?? 0,
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class AdminComment {
  const AdminComment({
    required this.commentId,
    required this.content,
    required this.likesCount,
    required this.userId,
    required this.eventId,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.isReply,
    required this.parentCommentId,
    required this.replyCount,
    required this.replies,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.isLiked,
  });

  final int commentId;
  final String content;
  final int likesCount;
  final int? userId;
  final int eventId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isReply;
  final int? parentCommentId;
  final int replyCount;
  final List<AdminComment> replies;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool isLiked;

  String get authorLabel =>
      (displayName?.trim().isNotEmpty ?? false)
          ? displayName!.trim()
          : (username?.trim().isNotEmpty ?? false)
              ? username!.trim()
              : 'Deleted user';

  factory AdminComment.fromJson(Map<String, dynamic> json) {
    return AdminComment(
      commentId: (json['commentId'] as num).toInt(),
      content: (json['content'] ?? '').toString(),
      likesCount: ((json['likesCount'] ?? 0) as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      eventId: (json['eventId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'].toString()).toLocal(),
      isDeleted: json['isDeleted'] == true,
      isReply: json['isReply'] == true,
      parentCommentId: (json['parentCommentId'] as num?)?.toInt(),
      replyCount: ((json['replyCount'] ?? 0) as num).toInt(),
      replies: ((json['replies'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AdminComment.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isLiked: json['isLiked'] == true,
    );
  }

  AdminComment copyWith({
    int? commentId,
    String? content,
    int? likesCount,
    int? userId,
    int? eventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isReply,
    int? parentCommentId,
    int? replyCount,
    List<AdminComment>? replies,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? isLiked,
  }) {
    return AdminComment(
      commentId: commentId ?? this.commentId,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isReply: isReply ?? this.isReply,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}