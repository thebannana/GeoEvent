import 'package:dio/dio.dart';

import '../models/ticket_scan_result.dart';

class TicketScannerApi {
  final Dio dio;

  TicketScannerApi(this.dio);

  Future<TicketScanResultDto> validateTicket({
    required int eventId,
    required String qrCode,
  }) async {
    final response = await dio.post(
      '/api/tickets/validate',
      data: {
        'eventId': eventId,
        'qrCode': qrCode,
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Invalid ticket scan response.');
    }

    return TicketScanResultDto.fromJson(Map<String, dynamic>.from(raw));
  }
}