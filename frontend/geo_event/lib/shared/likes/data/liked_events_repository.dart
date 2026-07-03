import '../models/liked_event.dart';
import 'liked_events_api.dart';

class LikedEventsRepository {
  const LikedEventsRepository(this._api);

  final LikedEventsApi _api;

  Future<List<LikedEvent>> getLikedEvents() {
    return _api.getLikedEvents();
  }

  Future<void> likeEvent(int eventId) {
    return _api.likeEvent(eventId);
  }

  Future<void> unlikeEvent(int eventId) {
    return _api.unlikeEvent(eventId);
  }
}