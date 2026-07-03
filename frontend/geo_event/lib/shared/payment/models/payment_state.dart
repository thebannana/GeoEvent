import 'payment_method.dart';
import 'payment_summary.dart';

class PaymentState {
  final PaymentSummary summary;
  final PaymentMethod selectedMethod;
  final bool isSubmitting;
  final String? errorMessage;
  final int? reservationId;

  const PaymentState({
    required this.summary,
    required this.selectedMethod,
    this.isSubmitting = false,
    this.errorMessage,
    this.reservationId,
  });

  bool get canSubmit => !isSubmitting && summary.quantity > 0;

  PaymentState copyWith({
    PaymentSummary? summary,
    PaymentMethod? selectedMethod,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    int? reservationId,
    bool clearReservationId = false,
  }) {
    return PaymentState(
      summary: summary ?? this.summary,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reservationId:
          clearReservationId ? null : (reservationId ?? this.reservationId),
    );
  }
}