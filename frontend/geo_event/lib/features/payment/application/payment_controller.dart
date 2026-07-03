import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/payment/models/payment_method.dart';
import '../../../../shared/payment/models/payment_state.dart';
import '../../../../shared/profile/models/paypal_approval_result.dart';
import '../../../../shared/tickets/data/tickets_repository.dart';
import '../../../../shared/tickets/models/ticket_models.dart';

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController({
    required this.ref,
    required this.ticketsRepository,
    required PaymentState initialState,
  }) : super(initialState);

  final Ref ref;
  final TicketsRepository ticketsRepository;

  void selectMethod(PaymentMethod method) {
    if (state.isSubmitting || state.summary.isFree) return;

    state = state.copyWith(
      selectedMethod: method,
      clearError: true,
    );
  }

  void setQuantity(int quantity) {
    if (state.isSubmitting || quantity < 1) return;

    state = state.copyWith(
      summary: state.summary.copyWith(quantity: quantity),
      clearError: true,
    );
  }

  Future<bool> submit({
    required Future<PayPalApprovalResult> Function({
      required String approveUrl,
      required String orderId,
      required int reservationId,
    }) onPayPalApproval,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearReservationId: true,
    );

    int? reservationId;
    var shouldCancelReservationOnError = false;

    try {
      final reservation = await ticketsRepository.createReservation(
        CreateReservationRequest(
          eventId: state.summary.eventId,
          eventTicketId: state.summary.eventTicketId,
          quantity: state.summary.quantity,
          currency: state.summary.currency,
        ),
      );

      reservationId = reservation.reservationId;
      shouldCancelReservationOnError = true;

      state = state.copyWith(reservationId: reservationId);

      if (state.summary.isFree) {
        await ticketsRepository.confirmReservation(
          reservationId,
          ConfirmReservationRequest(
            paymentMethod: 'Cash',
            currency: state.summary.currency,
          ),
        );

        shouldCancelReservationOnError = false;
        state = state.copyWith(
          isSubmitting: false,
          clearError: true,
        );
        return true;
      }

      if (state.selectedMethod.isCash) {
        await ticketsRepository.cashConfirmReservation(reservationId);

        shouldCancelReservationOnError = false;
        state = state.copyWith(
          isSubmitting: false,
          clearError: true,
        );
        return true;
      }

      if (state.selectedMethod.isPayPal) {
        final payPalOrder =
            await ticketsRepository.createPayPalOrder(reservationId);

        if (!payPalOrder.isValid) {
          throw const FormatException('PayPal approval response is invalid.');
        }

        debugPrint(
          'PayPal order created: reservationId=$reservationId, orderId=${payPalOrder.orderId}',
        );

        final approval = await onPayPalApproval(
          approveUrl: payPalOrder.approveUrl,
          orderId: payPalOrder.orderId,
          reservationId: reservationId,
        );

        debugPrint(
          'PayPal approval returned: approved=${approval.approved}, orderId=${approval.orderId}',
        );

        if (!approval.approved) {
          await _cancelReservationSilently(reservationId);

          state = state.copyWith(
            isSubmitting: false,
            clearReservationId: true,
            errorMessage: approval.error ?? 'PayPal payment was cancelled.',
          );
          return false;
        }

        final approvedOrderId = approval.orderId?.trim() ?? '';
        if (approvedOrderId.isEmpty) {
          await _cancelReservationSilently(reservationId);
          throw const FormatException('Returned PayPal order id is missing.');
        }

        if (approvedOrderId != payPalOrder.orderId.trim()) {
          await _cancelReservationSilently(reservationId);
          throw const FormatException(
            'Returned PayPal order does not match the created order.',
          );
        }

        debugPrint(
          'Capturing PayPal order: reservationId=$reservationId, orderId=$approvedOrderId',
        );

        await ticketsRepository.capturePayPalOrder(
          reservationId,
          approvedOrderId,
        );

        debugPrint(
          'PayPal capture completed: reservationId=$reservationId, orderId=$approvedOrderId',
        );

        shouldCancelReservationOnError = false;
        state = state.copyWith(
          isSubmitting: false,
          clearError: true,
        );
        return true;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unsupported payment method.',
      );
      return false;
    } catch (error, stackTrace) {
      if (reservationId != null && shouldCancelReservationOnError) {
        await _cancelReservationSilently(reservationId);
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not complete payment. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<void> _cancelReservationSilently(int reservationId) async {
    try {
      await ticketsRepository.cancelReservation(reservationId);
    } catch (_) {}
  }
}