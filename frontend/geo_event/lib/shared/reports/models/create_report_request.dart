import 'report_target_type.dart';

class CreateReportRequest {
  final ReportTargetType targetType;
  final int targetId;
  final String reason;
  final String description;

  const CreateReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    final trimmedDescription = description.trim();

    return {
      'targetType': targetType.apiValue,
      'targetId': targetId,
      'reason': reason,
      if (trimmedDescription.isNotEmpty) 'description': trimmedDescription,
    };
  }
}