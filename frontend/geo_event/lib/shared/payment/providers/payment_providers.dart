import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/payment/application/payment_controller.dart';
import '../../tickets/providers/ticket_providers.dart';
import '../models/payment_method.dart';
import '../models/payment_state.dart';
import '../models/payment_summary.dart';

final paymentControllerProvider = StateNotifierProvider.autoDispose
    .family<PaymentController, PaymentState, PaymentSummary>((ref, summary) {
  final ticketsRepository = ref.watch(ticketsRepositoryProvider);

  return PaymentController(
    ref: ref,
    ticketsRepository: ticketsRepository,
    initialState: PaymentState(
      summary: summary,
      selectedMethod: PaymentMethod.paypal,
    ),
  );
});