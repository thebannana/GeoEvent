class ActivityLog {
  final int logId;
  final int targetId;
  final String sessionId;
  final String actionType;
  final String targetType;
  final String metadata;
  final int? userId;
  final int? segmentId;
  final int? genreId;
  final DateTime createdAt;

  const ActivityLog({
    required this.logId,
    required this.targetId,
    required this.sessionId,
    required this.actionType,
    required this.targetType,
    required this.metadata,
    required this.userId,
    required this.segmentId,
    required this.genreId,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      logId: (json['logId'] as num?)?.toInt() ?? 0,
      targetId: (json['targetId'] as num?)?.toInt() ?? 0,
      sessionId: (json['sessionId'] ?? '').toString(),
      actionType: (json['actionType'] ?? '').toString(),
      targetType: (json['targetType'] ?? '').toString(),
      metadata: (json['metadata'] ?? '').toString(),
      userId: (json['userId'] as num?)?.toInt(),
      segmentId: (json['segmentId'] as num?)?.toInt(),
      genreId: (json['genreId'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}