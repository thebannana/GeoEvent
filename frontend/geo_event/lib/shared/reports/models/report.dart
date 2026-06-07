import 'report_status.dart';
import 'report_target_type.dart';

class Report {
  final int reportId;
  final ReportTargetType targetType;
  final int? targetId;
  final String reason;
  final String description;
  final ReportStatus status;
  final int? reporterId;
  final int? resolvedById;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Report({
    required this.reportId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
    required this.status,
    required this.reporterId,
    required this.resolvedById,
    required this.createdAt,
    required this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: (json['reportId'] as num).toInt(),
      targetType: ReportTargetType.fromJson(
        json['targetType'] as String? ?? 'Event',
      ),
      targetId: (json['targetId'] as num?)?.toInt(),
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: ReportStatus.fromJson(json['status'] as String? ?? 'Pending'),
      reporterId: (json['reporterId'] as num?)?.toInt(),
      resolvedById: (json['resolvedById'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
    );
  }
}