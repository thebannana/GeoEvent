import '../models/create_payment_request.dart';
import '../models/payment_result.dart';
import 'payment_api.dart';

class PaymentRepository {
  final PaymentApi _api;

  const PaymentRepository(this._api);

  Future<PaymentResult> submitPayment(CreatePaymentRequest request) {
    return _api.submitPayment(request);
  }
}