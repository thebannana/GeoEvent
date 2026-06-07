import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/reports/data/reports_repository.dart';
import '../../../shared/reports/models/create_report_request.dart';
import '../../../shared/reports/models/report_reason.dart';
import '../../../shared/reports/models/report_state.dart';
import '../../../shared/reports/providers/reports_providers.dart';

final reportControllerProvider =
    StateNotifierProvider.autoDispose
        .family<ReportController, ReportState, ReportState>(
  (ref, initialState) {
    final repository = ref.watch(reportsRepositoryProvider);
    return ReportController(
      repository: repository,
      initialState: initialState,
    );
  },
);

class ReportController extends StateNotifier<ReportState> {
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
    if (state.selectedReason == null) {
      state = state.copyWith(
        errorMessage: 'Please select a reason before submitting.',
      );
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
        reason: state.selectedReason!.label,
        description: state.description.trim(),
      );

      await repository.createReport(request);

      state = state.copyWith(
        isSubmitting: false,
        clearError: true,
      );

      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not submit report. Please try again.',
      );
      return false;
    }
  }
}