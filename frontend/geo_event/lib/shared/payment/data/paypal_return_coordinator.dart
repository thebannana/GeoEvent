import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayPalReturnResult {
  final bool approved;
  final String? orderId;

  const PayPalReturnResult._({
    required this.approved,
    this.orderId,
  });

  const PayPalReturnResult.approved({String? orderId})
      : this._(
          approved: true,
          orderId: orderId,
        );

  const PayPalReturnResult.cancelled()
      : this._(
          approved: false,
        );
}

class PayPalReturnCoordinatorState {
  final Map<int, PayPalReturnResult> byReservationId;

  const PayPalReturnCoordinatorState({
    this.byReservationId = const {},
  });

  PayPalReturnCoordinatorState copyWith({
    Map<int, PayPalReturnResult>? byReservationId,
  }) {
    return PayPalReturnCoordinatorState(
      byReservationId: byReservationId ?? this.byReservationId,
    );
  }
}

class PayPalReturnCoordinator
    extends StateNotifier<PayPalReturnCoordinatorState> {
  PayPalReturnCoordinator() : super(const PayPalReturnCoordinatorState());

  void complete({
    required int? reservationId,
    required PayPalReturnResult result,
  }) {
    if (reservationId == null) {
      return;
    }

    final updated = Map<int, PayPalReturnResult>.from(state.byReservationId);
    updated[reservationId] = result;
    state = state.copyWith(byReservationId: updated);
  }

  PayPalReturnResult? takeForReservation(int reservationId) {
    final existing = state.byReservationId[reservationId];
    if (existing == null) {
      return null;
    }

    final updated = Map<int, PayPalReturnResult>.from(state.byReservationId);
    updated.remove(reservationId);
    state = state.copyWith(byReservationId: updated);
    return existing;
  }
}

final payPalReturnCoordinatorProvider = StateNotifierProvider<
    PayPalReturnCoordinator, PayPalReturnCoordinatorState>(
  (ref) => PayPalReturnCoordinator(),
);