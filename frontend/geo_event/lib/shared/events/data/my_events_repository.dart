import '../models/my_event_response_dto.dart';
import 'my_events_api.dart';

class MyEventsRepository {
  const MyEventsRepository(this.api);

  final MyEventsApi api;

  Future<List<MyEventResponseDto>> getMyEvents(int organizerId) {
    return api.getMyEvents(organizerId);
  }

  Future<void> deleteEvent(int eventId) {
    return api.deleteEvent(eventId);
  }
}