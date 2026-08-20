import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/json_helpers.dart';

enum AdminEventViewStyle { list, grid2, grid3 }

enum AdminEventStatusFilter {
  all,
  pending,
  confirmed,
  cancelled,
  completed,
}

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
    return EventImageResponse(
      imageId: JsonHelpers.asInt(
            json['imageId'] ?? json['ImageId'],
          ) ??
          0,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '')
          .toString()
          .trim(),
      isCover: JsonHelpers.asBool(
        json['isCover'] ?? json['IsCover'],
      ),
      uploadedAt: JsonHelpers.parseDateTime(
        json['uploadedAt'] ?? json['UploadedAt'],
      ),
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
    if (cover != null && cover.isNotEmpty) {
      return cover;
    }

    for (final image in images) {
      final normalized = image.imageUrl.trim();

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    for (final image in imageUrls) {
      final normalized = image.trim();

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  String get category {
    return subGenreName ?? genreName ?? segmentName ?? 'Event';
  }

  String get displayTitleWithSegment {
    final segment = segmentName?.trim();

    if (segment == null || segment.isEmpty) {
      return displayTitle;
    }

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

    if (value == null) {
      return 'No date';
    }

    return value.formatDateTime(
      pattern: 'dd MMM yyyy • HH:mm',
    );
  }

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ?? json['Images'];

    final images = rawImages is List
        ? rawImages
            .whereType<Map>()
            .map(
              (item) => EventImageResponse.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((image) => image.imageUrl.trim().isNotEmpty)
            .toList(growable: false)
        : <EventImageResponse>[];

    final parsedImageUrls = JsonHelpers.asStringList(
      json['imageUrls'] ?? json['ImageUrls'],
    );

    final derivedImageUrls = images
        .map((image) => image.imageUrl.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    final mergedImageUrls = <String>[
      ...parsedImageUrls,
      ...derivedImageUrls.where(
        (url) => !parsedImageUrls.contains(url),
      ),
    ];

    final rawCoverImageUrl = JsonHelpers.normalize(
      json['coverImageUrl'] ?? json['CoverImageUrl'],
    );

    final derivedCoverImageUrl = images
        .where(
          (image) =>
              image.isCover &&
              image.imageUrl.trim().isNotEmpty,
        )
        .map((image) => image.imageUrl.trim())
        .cast<String?>()
        .firstWhere(
          (url) => url != null && url.isNotEmpty,
          orElse: () => null,
        );

    return AdminEvent(
      eventId: JsonHelpers.asInt(
            json['eventId'] ?? json['EventId'],
          ) ??
          0,
      organizerId: JsonHelpers.asInt(
        json['organizerId'] ?? json['OrganizerId'],
      ),
      segmentId: JsonHelpers.asInt(
        json['segmentId'] ?? json['SegmentId'],
      ),
      segmentName: JsonHelpers.normalize(
        json['segmentName'] ?? json['SegmentName'],
      ),
      segmentColor: JsonHelpers.normalize(
        json['segmentColor'] ?? json['SegmentColor'],
      ),
      genreId: JsonHelpers.asInt(
        json['genreId'] ?? json['GenreId'],
      ),
      genreName: JsonHelpers.normalize(
        json['genreName'] ?? json['GenreName'],
      ),
      subGenreId: JsonHelpers.asInt(
        json['subGenreId'] ?? json['SubGenreId'],
      ),
      subGenreName: JsonHelpers.normalize(
        json['subGenreName'] ?? json['SubGenreName'],
      ),
      title: (json['title'] ?? json['Title'] ?? '').toString().trim(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString()
          .trim(),
      latitude: JsonHelpers.asDouble(
        json['latitude'] ?? json['Latitude'],
      ),
      longitude: JsonHelpers.asDouble(
        json['longitude'] ?? json['Longitude'],
      ),
      startDateTime: JsonHelpers.parseDateTime(
        json['startDateTime'] ?? json['StartDateTime'],
      ),
      endDateTime: JsonHelpers.parseDateTime(
        json['endDateTime'] ?? json['EndDateTime'],
      ),
      capacity: JsonHelpers.asInt(
            json['capacity'] ?? json['Capacity'],
          ) ??
          0,
      price: JsonHelpers.asDouble(
        json['price'] ?? json['Price'],
      ),
      status: (json['status'] ?? json['Status'] ?? '').toString().trim(),
      isFeatured: JsonHelpers.asBool(
        json['isFeatured'] ?? json['IsFeatured'],
      ),
      viewCount: JsonHelpers.asInt(
            json['viewCount'] ?? json['ViewCount'],
          ) ??
          0,
      likesCount: JsonHelpers.asInt(
            json['likesCount'] ?? json['LikesCount'],
          ) ??
          0,
      isLiked: JsonHelpers.asBool(
        json['isLiked'] ?? json['IsLiked'],
      ),
      tags: JsonHelpers.normalize(
        json['tags'] ?? json['Tags'],
      ),
      accessibilityInfo: JsonHelpers.normalize(
        json['accessibilityInfo'] ?? json['AccessibilityInfo'],
      ),
      promoterName: JsonHelpers.normalize(
        json['promoterName'] ?? json['PromoterName'],
      ),
      locale: (json['locale'] ?? json['Locale'] ?? 'bs-BA')
          .toString()
          .trim(),
      createdAt: JsonHelpers.parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
      ),
      updatedAt: JsonHelpers.parseDateTime(
        json['updatedAt'] ?? json['UpdatedAt'],
      ),
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
      'images': images.map((image) => image.toJson()).toList(),
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
    if (capacity <= 0) {
      return 0;
    }

    return (reservedCount / capacity).clamp(0, 1).toDouble();
  }

  String get occupancyLabel {
    if (capacity <= 0) {
      return '$reservedCount reserved';
    }

    return '$reservedCount/$capacity';
  }

  factory EventReservationSummary.fromJson(Map<String, dynamic> json) {
    return EventReservationSummary(
      eventId: JsonHelpers.asInt(
            json['eventId'] ?? json['EventId'],
          ) ??
          0,
      capacity: JsonHelpers.asInt(
            json['capacity'] ?? json['Capacity'],
          ) ??
          0,
      reservedCount: JsonHelpers.asInt(
            json['reservedCount'] ?? json['ReservedCount'],
          ) ??
          0,
      confirmedCount: JsonHelpers.asInt(
            json['confirmedCount'] ?? json['ConfirmedCount'],
          ) ??
          0,
      pendingCount: JsonHelpers.asInt(
            json['pendingCount'] ?? json['PendingCount'],
          ) ??
          0,
      availableCount: JsonHelpers.asInt(
            json['availableCount'] ?? json['AvailableCount'],
          ) ??
          0,
      reservationCount: JsonHelpers.asInt(
            json['reservationCount'] ?? json['ReservationCount'],
          ) ??
          0,
      isSoldOut: JsonHelpers.asBool(
        json['isSoldOut'] ?? json['IsSoldOut'],
      ),
    );
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

  factory ManageableEventAttendeePreview.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManageableEventAttendeePreview(
      reservationId: JsonHelpers.asInt(
            json['reservationId'] ?? json['ReservationId'],
          ) ??
          0,
      userId: JsonHelpers.asInt(
            json['userId'] ?? json['UserId'],
          ) ??
          0,
      username: (json['username'] ?? json['Username'] ?? '')
          .toString()
          .trim(),
      avatarUrl: JsonHelpers.normalize(
        json['avatarUrl'] ?? json['AvatarUrl'],
      ),
      quantity: JsonHelpers.asInt(
            json['quantity'] ?? json['Quantity'],
          ) ??
          0,
    );
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

  String get authorLabel {
    if (displayName?.trim().isNotEmpty ?? false) {
      return displayName!.trim();
    }

    if (username?.trim().isNotEmpty ?? false) {
      return username!.trim();
    }

    return 'Deleted user';
  }

  factory AdminComment.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] ?? json['Replies'];

    return AdminComment(
      commentId: JsonHelpers.asInt(
            json['commentId'] ?? json['CommentId'],
          ) ??
          0,
      content: (json['content'] ?? json['Content'] ?? '')
          .toString()
          .trim(),
      likesCount: JsonHelpers.asInt(
            json['likesCount'] ?? json['LikesCount'],
          ) ??
          0,
      userId: JsonHelpers.asInt(
        json['userId'] ?? json['UserId'],
      ),
      eventId: JsonHelpers.asInt(
            json['eventId'] ?? json['EventId'],
          ) ??
          0,
      createdAt: JsonHelpers.parseDateTimeRequired(
        json['createdAt'] ?? json['CreatedAt'],
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        ),
      ),
      updatedAt: JsonHelpers.parseDateTime(
        json['updatedAt'] ?? json['UpdatedAt'],
      ),
      isDeleted: JsonHelpers.asBool(
        json['isDeleted'] ?? json['IsDeleted'],
      ),
      isReply: JsonHelpers.asBool(
        json['isReply'] ?? json['IsReply'],
      ),
      parentCommentId: JsonHelpers.asInt(
        json['parentCommentId'] ?? json['ParentCommentId'],
      ),
      replyCount: JsonHelpers.asInt(
            json['replyCount'] ?? json['ReplyCount'],
          ) ??
          0,
      replies: rawReplies is List
          ? rawReplies
              .whereType<Map>()
              .map(
                (item) => AdminComment.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      username: JsonHelpers.normalize(
        json['username'] ?? json['Username'],
      ),
      displayName: JsonHelpers.normalize(
        json['displayName'] ?? json['DisplayName'],
      ),
      avatarUrl: JsonHelpers.normalize(
        json['avatarUrl'] ?? json['AvatarUrl'],
      ),
      isLiked: JsonHelpers.asBool(
        json['isLiked'] ?? json['IsLiked'],
      ),
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