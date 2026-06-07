import '../models/my_event_response_dto.dart';
import 'my_events_api.dart';

class MyEventsRepository {
  final MyEventsApi _api;

  const MyEventsRepository(this._api);

  Future<List<MyEventResponseDto>> getMyEvents(int organizerId) {
    return _api.getMyEvents(organizerId);
  }

  Future<void> deleteEvent(int eventId) {
  return _api.deleteEvent(eventId);
}
}