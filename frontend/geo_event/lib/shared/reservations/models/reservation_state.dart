import '../../../../shared/reservations/models/reservation.dart';
import '../../../../shared/reservations/models/reservation_status.dart';

class ReservationsState {
  final List<Reservation> items;
  final ReservationStatus? statusFilter;
  final int? eventIdFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFetchingMore;
  final bool hasMore;
  final int page;
  final int pageSize;
  final int totalCount;
  final String? error;

  const ReservationsState({
    this.items = const [],
    this.statusFilter,
    this.eventIdFilter,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.error,
  });

  const ReservationsState.initial()
      : items = const [],
        statusFilter = null,
        eventIdFilter = null,
        isLoading = true,
        isRefreshing = false,
        isFetchingMore = false,
        hasMore = true,
        page = 1,
        pageSize = 20,
        totalCount = 0,
        error = null;

  ReservationsState copyWith({
    List<Reservation>? items,
    ReservationStatus? statusFilter,
    bool clearStatusFilter = false,
    int? eventIdFilter,
    bool clearEventIdFilter = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFetchingMore,
    bool? hasMore,
    int? page,
    int? pageSize,
    int? totalCount,
    String? error,
    bool clearError = false,
  }) {
    return ReservationsState(
      items: items ?? this.items,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      eventIdFilter:
          clearEventIdFilter ? null : eventIdFilter ?? this.eventIdFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : error ?? this.error,
    );
  }
}