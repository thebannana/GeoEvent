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
      logId: json['logId'] as int,
      targetId: json['targetId'] as int,
      sessionId: json['sessionId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      metadata: json['metadata'] as String? ?? '',
      userId: json['userId'] as int?,
      segmentId: json['segmentId'] as int?,
      genreId: json['genreId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}