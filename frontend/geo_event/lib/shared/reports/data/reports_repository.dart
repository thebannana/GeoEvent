import '../models/create_report_request.dart';
import '../models/get_my_reports_request.dart';
import '../models/paged_result.dart';
import '../models/report.dart';
import 'reports_api.dart';

class ReportsRepository {
  final ReportsApi api;

  const ReportsRepository(this.api);

  Future<Report> createReport(CreateReportRequest request) {
    return api.createReport(request);
  }

  Future<PagedResult<Report>> getMyReports(GetMyReportsRequest request) {
    return api.getMyReports(request);
  }
}