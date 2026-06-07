import 'package:dio/dio.dart';

import '../models/create_payment_request.dart';
import '../models/payment_result.dart';

class PaymentApi {
  final Dio _dio;

  const PaymentApi(this._dio);

  Future<PaymentResult> submitPayment(CreatePaymentRequest request) async {
    final response = await _dio.post(
      '/api/payments/checkout',
      data: request.toJson(),
    );

    return PaymentResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}