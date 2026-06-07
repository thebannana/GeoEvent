import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/payment/models/complete_checkout_request.dart';
import '../../../shared/payment/models/payment_method.dart';
import '../../../shared/payment/models/payment_state.dart';
import '../../../shared/tickets/data/tickets_repository.dart';

class PaymentController extends StateNotifier<PaymentState> {
  final Ref ref;
  final TicketsRepository ticketsRepository;

  PaymentController({
    required this.ref,
    required this.ticketsRepository,
    required PaymentState initialState,
  }) : super(initialState);

  void selectMethod(PaymentMethod method) {
    state = state.copyWith(
      selectedMethod: method,
      clearError: true,
    );
  }

  void setQuantity(int quantity) {
    if (quantity < 1) return;

    state = state.copyWith(
      summary: state.summary.copyWith(quantity: quantity),
      clearError: true,
    );
  }

Future<bool> submit({
  required Future<bool> Function(double amount, String currency) onPayPalCheckout,
}) async {
  state = state.copyWith(
    isSubmitting: true,
    clearError: true,
  );

  try {
    if (state.selectedMethod == PaymentMethod.paypal) {
      final paypalSuccess = await onPayPalCheckout(
        state.summary.total,
        state.summary.currency,
      );

      if (!paypalSuccess) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'PayPal payment was cancelled.',
        );
        return false;
      }
    }

    await ticketsRepository.completeCheckout(
      CompleteCheckoutRequest(
        eventId: state.summary.eventId,
        eventTicketId: state.summary.eventTicketId,
        quantity: state.summary.quantity,
        currency: state.summary.currency,
        paymentReference: _generatePaymentReference(),
        paymentMethod: state.selectedMethod,
        amount: state.summary.total,
      ),
    );

    state = state.copyWith(
      isSubmitting: false,
      clearError: true,
    );

    return true;
  } catch (e) {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: _readMessage(e),
    );
    return false;
  }
}

  String _generatePaymentReference() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'PAY-$now-$rand';
  }

  String _readMessage(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return 'Could not complete payment. Please try again.';
    }
    return text;
  }
}