import '../models/admin_report.dart';
import 'admin_reports_api.dart';

class AdminReportsRepository {
  const AdminReportsRepository(this.api);

  final AdminReportsApi api;

  Future<AdminReportsPage> getReports(AdminReportsQuery query) {
    return api.getReports(query);
  }

  Future<AdminReport> getReportById(int reportId) {
    return api.getReportById(reportId);
  }

  Future<AdminReport> updateReportStatus({
    required int reportId,
    required AdminReportQueueFilter status,
    String? resolutionNote,
    String? moderatorAction,
  }) {
    return api.updateReportStatus(
      reportId: reportId,
      status: status,
      resolutionNote: resolutionNote,
      moderatorAction: moderatorAction,
    );
  }
}