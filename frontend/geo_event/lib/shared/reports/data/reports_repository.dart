import '../models/create_report_request.dart';
import '../models/report.dart';
import 'reports_api.dart';

class ReportsRepository {
  final ReportsApi _api;

  const ReportsRepository(this._api);

  Future<Report> createReport(CreateReportRequest request) {
    return _api.createReport(request);
  }

  Future<List<Report>> getMyReports() {
    return _api.getMyReports();
  }
}