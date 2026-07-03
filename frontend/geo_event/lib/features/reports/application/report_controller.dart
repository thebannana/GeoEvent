import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/reports/data/reports_repository.dart';
import '../../../shared/reports/models/create_report_request.dart';
import '../../../shared/reports/models/report_reason.dart';
import '../../../shared/reports/models/report_state.dart';
import '../../../shared/reports/providers/reports_providers.dart';

final reportControllerProvider = StateNotifierProvider.autoDispose
    .family<ReportController, ReportState, ReportState>(
  (ref, initialState) {
    return ReportController(
      repository: ref.watch(reportsRepositoryProvider),
      initialState: initialState,
    );
  },
);

class ReportController extends StateNotifier<ReportState> {
  static const String _reasonRequiredMessage =
      'Please select a reason before submitting.';
  static const String _fallbackSubmitErrorMessage =
      'Could not submit report. Please try again.';

  final ReportsRepository repository;

  ReportController({
    required this.repository,
    required ReportState initialState,
  }) : super(initialState);

  void selectReason(ReportReason reason) {
    state = state.copyWith(
      selectedReason: reason,
      clearError: true,
    );
  }

  void setDescription(String value) {
    state = state.copyWith(
      description: value,
      clearError: true,
    );
  }

  Future<bool> submit() async {
    final selectedReason = state.selectedReason;
    if (selectedReason == null) {
      state = state.copyWith(errorMessage: _reasonRequiredMessage);
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final request = CreateReportRequest(
        targetType: state.targetType,
        targetId: state.targetId,
        reason: selectedReason.label,
        description: state.description.trim(),
      );

      await repository.createReport(request);

      state = state.copyWith(
        isSubmitting: false,
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      final mappedMessage = ErrorMapper.toMessage(
        error,
        stackTrace: stackTrace,
        fallbackMessage: _fallbackSubmitErrorMessage,
      );

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: mappedMessage,
      );
      return false;
    }
  }
}