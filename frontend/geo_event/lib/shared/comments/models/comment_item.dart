class CommentItem {
  final int commentId;
  final String content;
  final int likesCount;
  final int? userId;
  final int? eventId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isReply;
  final int? parentCommentId;
  final int replyCount;
  final List<CommentItem> replies;

  final String? username;
  final String? displayName;
  final String? avatarUrl;

  final bool isLiked;
  final bool areRepliesLoaded;
  final bool isReplyLoading;

  const CommentItem({
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
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isLiked = false,
    this.areRepliesLoaded = false,
    this.isReplyLoading = false,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    final replies = rawReplies is List
        ? rawReplies
            .whereType<Map>()
            .map((e) => CommentItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CommentItem>[];

    return CommentItem(
      commentId: _asInt(json['commentId']),
      content: (json['content'] ?? '').toString(),
      likesCount: _asInt(json['likesCount']),
      userId: _asNullableInt(json['userId']),
      eventId: _asNullableInt(json['eventId']),
      createdAt: _asDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _asDateTime(json['updatedAt']),
      isDeleted: _asBool(json['isDeleted']),
      isReply: _asBool(json['isReply']),
      parentCommentId: _asNullableInt(json['parentCommentId']),
      replyCount: _asInt(json['replyCount']),
      replies: replies,
      username: _asNullableString(json['username']),
      displayName: _asNullableString(json['displayName']),
      avatarUrl: _asNullableString(json['avatarUrl']),
      isLiked: _asBool(json['isLiked']),
    );
  }

  CommentItem copyWith({
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
    List<CommentItem>? replies,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? isLiked,
    bool? areRepliesLoaded,
    bool? isReplyLoading,
  }) {
    return CommentItem(
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
      areRepliesLoaded: areRepliesLoaded ?? this.areRepliesLoaded,
      isReplyLoading: isReplyLoading ?? this.isReplyLoading,
    );
  }

  String get authorName {
    if ((displayName ?? '').trim().isNotEmpty) return displayName!.trim();
    if ((username ?? '').trim().isNotEmpty) return username!.trim();
    if (userId != null) return 'User #$userId';
    return 'Unknown user';
  }

  String get authorHandle {
    if ((username ?? '').trim().isNotEmpty) return '@${username!.trim()}';
    return '';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final text = '$value'.toLowerCase().trim();
    return text == 'true' || text == '1';
  }

static DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  if (raw.endsWith('Z') || raw.contains('+')) {
    return parsed.toLocal();
  }

  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}