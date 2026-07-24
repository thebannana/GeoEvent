import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/admin_refund.dart';

class AdminRefundsApi {
  const AdminRefundsApi(this.dio);

  final Dio dio;

  Future<AdminRefundRequestsPage> getRefundRequests(
    AdminRefundRequestsQuery query,
  ) async {
    final response = await dio.get(
      ApiEndpoints.adminRefundRequests,
      queryParameters: query.toQueryParameters(),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminRefundRequestsPage.fromJson(
      asMap(
        response.data,
        fallbackMessage: 'Invalid admin refund requests response.',
      ),
    );
  }

  Future<void> approveRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) async {
    await dio.post(
      ApiEndpoints.approveRefund(
        eventId: eventId,
        reservationId: reservationId,
      ),
      data: {
        'decisionReason': normalizeNullableString(decisionReason),
        'moderatorAction': normalizeNullableString(moderatorAction),
      }..removeWhere((key, value) => value == null),
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Future<void> rejectRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) async {
    await dio.post(
      ApiEndpoints.rejectRefund(
        eventId: eventId,
        reservationId: reservationId,
      ),
      data: {
        'decisionReason': normalizeNullableString(decisionReason),
        'moderatorAction': normalizeNullableString(moderatorAction),
      }..removeWhere((key, value) => value == null),
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Map<String, dynamic> asMap(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException(fallbackMessage);
  }

  String? normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}