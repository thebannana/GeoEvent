import '../../events/models/paged_result.dart';
import '../models/liked_event.dart';
import 'liked_events_api.dart';

class LikedEventsRepository {
  const LikedEventsRepository(this.api);

  final LikedEventsApi api;

  Future<PagedResult<LikedEvent>> getLikedEventsPaged({
    int page = 1,
    int pageSize = 20,
  }) {
    return api.getLikedEventsPaged(
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> likeEvent(int eventId) => api.likeEvent(eventId);

  Future<void> unlikeEvent(int eventId) => api.unlikeEvent(eventId);
}