import '../models/event_taxonomy_models.dart';
import 'event_taxonomy_api.dart';

class EventTaxonomyRepository {
  final EventTaxonomyApi _api;

  EventTaxonomyRepository(this._api);

  Future<List<SegmentLookup>> getSegments() => _api.getSegments();

  Future<List<GenreLookup>> getGenresForSegment(int segmentId) {
    return _api.getGenresForSegment(segmentId);
  }

  Future<List<SubGenreLookup>> getSubGenresForGenre(int genreId) {
    return _api.getSubGenresForGenre(genreId);
  }
}