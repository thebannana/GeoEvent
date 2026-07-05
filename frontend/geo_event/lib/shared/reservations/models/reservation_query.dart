import 'reservation_status.dart';

class ReservationsQuery {
  final ReservationStatus? status;
  final int? eventId;
  final int page;
  final int pageSize;

  static const int defaultPage = 1;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  const ReservationsQuery({
    this.status,
    this.eventId,
    this.page = defaultPage,
    this.pageSize = defaultPageSize,
  });

  ReservationsQuery copyWith({
    Object? status = _sentinel,
    Object? eventId = _sentinel,
    int? page,
    int? pageSize,
  }) {
    return ReservationsQuery(
      status: identical(status, _sentinel)
          ? this.status
          : status as ReservationStatus?,
      eventId: identical(eventId, _sentinel)
          ? this.eventId
          : eventId as int?,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  ReservationsQuery firstPage() {
    return copyWith(page: 1);
  }

  ReservationsQuery nextPage() {
    return copyWith(page: page + 1);
  }

  int get normalizedPage => page < 1 ? 1 : page;

  int get normalizedPageSize {
    if (pageSize <= 0) return defaultPageSize;
    if (pageSize > maxPageSize) return maxPageSize;
    return pageSize;
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': normalizedPage,
      'pageSize': normalizedPageSize,
      if (status != null) 'status': status!.apiValue,
      if (eventId != null) 'eventId': eventId,
    };
  }
}

const _sentinel = Object();