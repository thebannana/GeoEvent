import '../models/my_event_response_dto.dart';
import '../models/paged_response.dart';
import 'my_events_api.dart';

class MyEventsRepository {
  const MyEventsRepository(this.api);

  final MyEventsApi api;

  Future<PagedResponse<MyEventResponseDto>> getMyEvents({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? status,
    bool? canViewReservations,
  }) {
    return api.getMyEvents(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      status: status,
      canViewReservations: canViewReservations,
    );
  }

  Future<void> deleteEvent(int eventId) {
    return api.deleteEvent(eventId);
  }
}