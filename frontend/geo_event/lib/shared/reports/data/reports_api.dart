import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/create_report_request.dart';
import '../models/get_my_reports_request.dart';
import '../models/paged_result.dart';
import '../models/report.dart';

class ReportsApi {
  final Dio _dio;

  const ReportsApi(this._dio);

  Future<Report> createReport(CreateReportRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.reportsBase,
      data: request.toJson(),
    );

    final json = Map<String, dynamic>.from(response.data as Map);
    return Report.fromJson(json);
  }

  Future<PagedResult<Report>> getMyReports(GetMyReportsRequest request) async {
    final response = await _dio.get(
      ApiEndpoints.myReports,
      queryParameters: request.toQuery(),
    );

    final json = Map<String, dynamic>.from(response.data as Map);

    return PagedResult<Report>.fromJson(
      json,
      fromJsonT: (item) => Report.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    );
  }
}