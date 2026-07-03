import '../../../shared/events/models/create_event_models.dart';
import '../../../shared/tickets/models/ticket_models.dart';

class EventDetailsState {
  final EventItem? event;
  final List<EventTicketItem> tickets;
  final EventReservationSummaryItem? reservationSummary;
  final List<EventAttendeeItem> attendees;
  final bool isLoading;
  final bool isRefreshing;
  final bool isTogglingLike;
  final bool isLoadingTickets;
  final bool isLoadingAttendees;
  final String? error;

  const EventDetailsState({
    this.event,
    this.tickets = const [],
    this.reservationSummary,
    this.attendees = const [],
    this.isLoading = true,
    this.isRefreshing = false,
    this.isTogglingLike = false,
    this.isLoadingTickets = false,
    this.isLoadingAttendees = false,
    this.error,
  });

  bool get hasData => event != null;
  bool get hasError => error != null && error!.trim().isNotEmpty;

  bool get hasTickets => tickets.isNotEmpty;
  bool get hasAttendees => attendees.isNotEmpty;
  bool get isSoldOut =>
      reservationSummary?.isSoldOut == true ||
      tickets.where((t) => t.isActive).every((t) => t.isSoldOut);

  int get availableCapacity =>
      reservationSummary?.availableCount ??
      ((event?.capacity ?? 0) - (reservationSummary?.reservedCount ?? 0));

  EventDetailsState copyWith({
    EventItem? event,
    bool clearEvent = false,
    List<EventTicketItem>? tickets,
    EventReservationSummaryItem? reservationSummary,
    bool clearReservationSummary = false,
    List<EventAttendeeItem>? attendees,
    bool? isLoading,
    bool? isRefreshing,
    bool? isTogglingLike,
    bool? isLoadingTickets,
    bool? isLoadingAttendees,
    String? error,
    bool clearError = false,
  }) {
    return EventDetailsState(
      event: clearEvent ? null : (event ?? this.event),
      tickets: tickets ?? this.tickets,
      reservationSummary: clearReservationSummary
          ? null
          : (reservationSummary ?? this.reservationSummary),
      attendees: attendees ?? this.attendees,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isTogglingLike: isTogglingLike ?? this.isTogglingLike,
      isLoadingTickets: isLoadingTickets ?? this.isLoadingTickets,
      isLoadingAttendees: isLoadingAttendees ?? this.isLoadingAttendees,
      error: clearError ? null : (error ?? this.error),
    );
  }
}