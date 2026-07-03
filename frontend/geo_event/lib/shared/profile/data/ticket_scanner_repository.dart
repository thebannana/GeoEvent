import '../models/ticket_scan_result.dart';
import 'ticket_scanner_api.dart';

class TicketScannerRepository {
  const TicketScannerRepository(this.api);

  final TicketScannerApi api;

  Future<TicketScanResultDto> validateTicket({
    required int eventId,
    required String qrCode,
  }) {
    return api.validateTicket(
      eventId: eventId,
      qrCode: qrCode,
    );
  }
}