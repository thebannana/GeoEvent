import 'report_reason.dart';
import 'report_target_type.dart';

class ReportState {
  final ReportTargetType targetType;
  final int targetId;
  final String? targetTitle;
  final String? targetSubtitle;
  final String? targetImageUrl;
  final ReportReason? selectedReason;
  final String description;
  final bool isSubmitting;
  final String? errorMessage;

  const ReportState({
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.targetSubtitle,
    this.targetImageUrl,
    this.selectedReason,
    this.description = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get canSubmit => selectedReason != null && !isSubmitting;

  ReportState copyWith({
    ReportTargetType? targetType,
    int? targetId,
    String? targetTitle,
    String? targetSubtitle,
    String? targetImageUrl,
    ReportReason? selectedReason,
    String? description,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearReason = false,
  }) {
    return ReportState(
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetTitle: targetTitle ?? this.targetTitle,
      targetSubtitle: targetSubtitle ?? this.targetSubtitle,
      targetImageUrl: targetImageUrl ?? this.targetImageUrl,
      selectedReason: clearReason
          ? null
          : (selectedReason ?? this.selectedReason),
      description: description ?? this.description,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}