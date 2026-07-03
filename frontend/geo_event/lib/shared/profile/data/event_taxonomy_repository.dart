import '../models/event_taxonomy_models.dart';
import 'event_taxonomy_api.dart';

class EventTaxonomyRepository {
  const EventTaxonomyRepository(this.api);

  final EventTaxonomyApi api;

  Future<List<SegmentLookup>> getSegments() => api.getSegments();

  Future<List<GenreLookup>> getGenresForSegment(int segmentId) {
    return api.getGenresForSegment(segmentId);
  }

  Future<List<SubGenreLookup>> getSubGenresForGenre(int genreId) {
    return api.getSubGenresForGenre(genreId);
  }
}