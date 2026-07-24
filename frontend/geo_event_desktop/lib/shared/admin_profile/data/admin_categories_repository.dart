import '../models/categories.dart';
import '../models/paged_response.dart';
import 'admin_categories_api.dart';

class AdminCategoriesRepository {
  const AdminCategoriesRepository(this.api);

  final AdminCategoriesApi api;

  Future<List<AdminSegment>> getSegments() => api.getSegments();

  Future<PagedResponse<AdminSegment>> getSegmentsPage({
    required int page,
    required int pageSize,
    String? searchTerm,
  }) {
    return api.getSegmentsPage(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }

  Future<PagedResponse<AdminGenre>> getGenresPage({
    required int page,
    required int pageSize,
    String? searchTerm,
  }) {
    return api.getGenresPage(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }

  Future<PagedResponse<AdminSubGenre>> getSubGenresPage({
    required int page,
    required int pageSize,
    String? searchTerm,
  }) {
    return api.getSubGenresPage(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }

  Future<AdminSegment> createSegment({
    required String name,
    String? iconUrl,
    String? color,
    bool isActive = true,
  }) {
    return api.createSegment(
      name: name,
      iconUrl: iconUrl,
      color: color,
      isActive: isActive,
    );
  }

  Future<AdminSegment> updateSegment({
    required int segmentId,
    String? name,
    String? iconUrl,
    String? color,
    bool? isActive,
  }) {
    return api.updateSegment(
      segmentId: segmentId,
      name: name,
      iconUrl: iconUrl,
      color: color,
      isActive: isActive,
    );
  }

  Future<AdminGenre> createGenre({
    required int segmentId,
    required String name,
    bool isActive = true,
  }) {
    return api.createGenre(
      segmentId: segmentId,
      name: name,
      isActive: isActive,
    );
  }

  Future<AdminGenre> updateGenre({
    required int genreId,
    int? segmentId,
    String? name,
    bool? isActive,
  }) {
    return api.updateGenre(
      genreId: genreId,
      segmentId: segmentId,
      name: name,
      isActive: isActive,
    );
  }

  Future<AdminSubGenre> createSubGenre({
    required int genreId,
    required String name,
    bool isActive = true,
  }) {
    return api.createSubGenre(
      genreId: genreId,
      name: name,
      isActive: isActive,
    );
  }

  Future<AdminSubGenre> updateSubGenre({
    required int subGenreId,
    int? genreId,
    String? name,
    bool? isActive,
  }) {
    return api.updateSubGenre(
      subGenreId: subGenreId,
      genreId: genreId,
      name: name,
      isActive: isActive,
    );
  }
}