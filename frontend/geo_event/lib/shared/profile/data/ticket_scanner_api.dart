import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/ticket_scan_result.dart';

class TicketScannerApi {
  const TicketScannerApi(this._dio);

  final Dio _dio;

  Future<TicketScanResultDto> validateTicket({
    required int eventId,
    required String qrCode,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.validateTicket,
      data: {
        'eventId': eventId,
        'qrCode': qrCode.trim(),
      },
    );

    final map = _tryMap(response.data);
    if (map == null) {
      throw const FormatException('Invalid ticket scan response.');
    }

    return TicketScanResultDto.fromJson(map);
  }

  Map<String, dynamic>? _tryMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }
}