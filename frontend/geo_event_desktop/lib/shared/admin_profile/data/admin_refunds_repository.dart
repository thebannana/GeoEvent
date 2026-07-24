import '../models/admin_refund.dart';
import 'admin_refunds_api.dart';

class AdminRefundsRepository {
  const AdminRefundsRepository(this.api);

  final AdminRefundsApi api;

  Future<AdminRefundRequestsPage> getRefundRequests(
    AdminRefundRequestsQuery query,
  ) {
    return api.getRefundRequests(query);
  }

  Future<void> approveRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) {
    return api.approveRefund(
      eventId: eventId,
      reservationId: reservationId,
      decisionReason: decisionReason,
      moderatorAction: moderatorAction,
    );
  }

  Future<void> rejectRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) {
    return api.rejectRefund(
      eventId: eventId,
      reservationId: reservationId,
      decisionReason: decisionReason,
      moderatorAction: moderatorAction,
    );
  }
}