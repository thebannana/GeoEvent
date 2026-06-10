import '../models/ticket_scan_result.dart';
import 'ticket_scanner_api.dart';

class TicketScannerRepository {
  final TicketScannerApi api;

  TicketScannerRepository(this.api);

  Future<TicketScanResultDto> validateTicket({
    required int eventId,
    required String qrCode,
  }) {
    return api.validateTicket(eventId: eventId, qrCode: qrCode);
  }
}