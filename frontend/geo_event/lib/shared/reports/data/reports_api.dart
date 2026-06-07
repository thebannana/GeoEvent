import 'package:dio/dio.dart';

import '../models/create_report_request.dart';
import '../models/report.dart';

class ReportsApi {
  final Dio _dio;

  const ReportsApi(this._dio);

  Future<Report> createReport(CreateReportRequest request) async {
    final response = await _dio.post(
      '/api/reports',
      data: request.toJson(),
    );

    return Report.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Report>> getMyReports() async {
    final response = await _dio.get('/api/reports/my');
    final data = response.data as List<dynamic>? ?? const [];

    return data
        .map((e) => Report.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}