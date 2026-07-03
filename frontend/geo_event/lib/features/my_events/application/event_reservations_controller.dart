import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/reservations/data/organizer_reservations_repository.dart';
import '../../../../shared/reservations/models/organizer_reservation.dart';

class EventReservationsState {
  const EventReservationsState({
    this.loading = false,
    this.removing = false,
    this.removingReservationId,
    this.markingCashCollected = false,
    this.cashCollectionReservationId,
    this.errorMessage,
  });

  final bool loading;
  final bool removing;
  final int? removingReservationId;
  final bool markingCashCollected;
  final int? cashCollectionReservationId;
  final String? errorMessage;

  EventReservationsState copyWith({
    bool? loading,
    bool? removing,
    int? removingReservationId,
    bool? markingCashCollected,
    int? cashCollectionReservationId,
    String? errorMessage,
    bool clearRemovingReservationId = false,
    bool clearCashCollectionReservationId = false,
    bool clearErrorMessage = false,
  }) {
    return EventReservationsState(
      loading: loading ?? this.loading,
      removing: removing ?? this.removing,
      removingReservationId: clearRemovingReservationId
          ? null
          : (removingReservationId ?? this.removingReservationId),
      markingCashCollected:
          markingCashCollected ?? this.markingCashCollected,
      cashCollectionReservationId: clearCashCollectionReservationId
          ? null
          : (cashCollectionReservationId ?? this.cashCollectionReservationId),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final eventReservationsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventReservationsController, EventReservationsState, int>(
  (ref, eventId) {
    return EventReservationsController(
      eventId: eventId,
      repository: ref.watch(organizerReservationsRepositoryProvider),
    );
  },
);

class EventReservationsController
    extends StateNotifier<EventReservationsState> {
  EventReservationsController({
    required this.eventId,
    required this.repository,
  }) : super(const EventReservationsState());

  final int eventId;
  final OrganizerReservationsRepository repository;

  Future<List<OrganizerReservationDto>> loadReservations() {
    return repository.getEventReservations(eventId);
  }

  Future<void> removeAttendee(
    int reservationId, {
    String? reason,
  }) async {
    state = state.copyWith(
      removing: true,
      removingReservationId: reservationId,
      clearErrorMessage: true,
    );

    try {
      await repository.removeAttendee(
        eventId,
        reservationId,
        reason: reason,
      );

      state = state.copyWith(
        removing: false,
        clearRemovingReservationId: true,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        removing: false,
        clearRemovingReservationId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markCashCollected(int reservationId) async {
    state = state.copyWith(
      markingCashCollected: true,
      cashCollectionReservationId: reservationId,
      clearErrorMessage: true,
    );

    try {
      await repository.markCashCollected(eventId, reservationId);

      state = state.copyWith(
        markingCashCollected: false,
        clearCashCollectionReservationId: true,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        markingCashCollected: false,
        clearCashCollectionReservationId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}