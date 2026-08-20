import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/admin_report.dart';

class AdminReportsApi {
  const AdminReportsApi(this.dio);

  final Dio dio;

  Future<AdminReportsPage> getReports(AdminReportsQuery query) async {
    try {
      final response = await dio.get(
        ApiEndpoints.adminReports,
        queryParameters: query.toQueryParameters(),
        options: Options(
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      );

      return AdminReportsPage.fromJson(
        _asMap(
          response.data,
          fallbackMessage: 'Invalid admin reports response.',
        ),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AdminReport> getReportById(int reportId) async {
    try {
      final response = await dio.get(
        '${ApiEndpoints.adminReports}/$reportId',
        options: Options(
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      );

      return AdminReport.fromJson(
        _asMap(
          response.data,
          fallbackMessage: 'Invalid admin report detail response.',
        ),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AdminReport> updateReportStatus({
    required int reportId,
    required AdminReportQueueFilter status,
    String? resolutionNote,
    String? moderatorAction,
  }) async {
    try {
      _assertUpdatableStatus(status);

      final response = await dio.post(
        '${ApiEndpoints.adminReports}/$reportId/status',
        data: {
          'status': _statusToApi(status),
          'resolutionNote': _normalizeNullableString(resolutionNote),
          'moderatorAction': _normalizeNullableString(moderatorAction),
        }..removeWhere((key, value) => value == null),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: const {
            'Accept': 'application/json',
          },
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      );

      return AdminReport.fromJson(
        _asMap(
          response.data,
          fallbackMessage: 'Invalid report status update response.',
        ),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppException(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  void _assertUpdatableStatus(AdminReportQueueFilter status) {
    if (status == AdminReportQueueFilter.all ||
        status == AdminReportQueueFilter.open ||
        status == AdminReportQueueFilter.unknown) {
      throw const FormatException(
        'Report status can only be changed to inReview, resolved, or rejected.',
      );
    }
  }

  String _statusToApi(AdminReportQueueFilter status) {
    switch (status) {
      case AdminReportQueueFilter.inReview:
        return 'UnderReview';

      case AdminReportQueueFilter.resolved:
        return 'Resolved';

      case AdminReportQueueFilter.rejected:
        return 'Dismissed';

      case AdminReportQueueFilter.all:
      case AdminReportQueueFilter.open:
      case AdminReportQueueFilter.unknown:
        throw const FormatException(
          'Unsupported report update status.',
        );
    }
  }

  Map<String, dynamic> _asMap(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    throw FormatException(fallbackMessage);
  }

  String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}