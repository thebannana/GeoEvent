import '../../reservations/models/reservation_status.dart';
import '../data/organizer_reservations_api.dart';
import 'organizer_reservation.dart';

class EventReservationsState {
  const EventReservationsState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasLoadedOnce = false,
    this.page = 0,
    this.pageSize = OrganizerReservationsApi.defaultPageSize,
    this.totalCount = 0,
    this.totalPages = 0,
    this.hasNextPage = true,
    this.status,
    this.removing = false,
    this.removingReservationId,
    this.markingCashCollected = false,
    this.cashCollectionReservationId,
    this.errorMessage,
  });

  final List<OrganizerReservationDto> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasLoadedOnce;

  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final ReservationStatus? status;

  final bool removing;
  final int? removingReservationId;
  final bool markingCashCollected;
  final int? cashCollectionReservationId;
  final String? errorMessage;

  List<OrganizerReservationDto> get confirmedReservations => items
      .where((r) => r.status.trim().toLowerCase() == 'confirmed')
      .toList(growable: false);

  EventReservationsState copyWith({
    List<OrganizerReservationDto>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasLoadedOnce,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    bool? hasNextPage,
    ReservationStatus? status,
    bool clearStatus = false,
    bool? removing,
    int? removingReservationId,
    bool clearRemovingReservationId = false,
    bool? markingCashCollected,
    int? cashCollectionReservationId,
    bool clearCashCollectionReservationId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EventReservationsState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      status: clearStatus ? null : (status ?? this.status),
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