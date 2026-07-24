import 'dart:typed_data';

import '../models/admin_event.dart';
import '../models/paged_response.dart';
import 'admin_events_api.dart';

class AdminEventsRepository {
  const AdminEventsRepository(this.api);

  final AdminEventsApi api;

  Future<PagedResponse<AdminEvent>> getEvents({
    int page = 1,
    int pageSize = 10,
    String? searchTerm,
    String? status,
    int? organizerId,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    double? minPrice,
    double? maxPrice,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isFeatured,
    bool? canViewReservations,
    String? sortBy,
    bool? sortDescending,
  }) {
    return api.getEvents(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      status: status,
      organizerId: organizerId,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      fromDate: fromDate,
      toDate: toDate,
      isFeatured: isFeatured,
      canViewReservations: canViewReservations,
      sortBy: sortBy,
      sortDescending: sortDescending,
    );
  }

  Future<AdminEvent> getEventById(int eventId) {
    return api.getEventById(eventId);
  }

  Future<AdminEvent> updateEvent({
    required int eventId,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? capacity,
    double? price,
    bool? isFeatured,
    String? tags,
    String? accessibilityInfo,
    String? promoterName,
    String? locale,
  }) {
    return api.updateEvent(
      eventId: eventId,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      capacity: capacity,
      price: price,
      isFeatured: isFeatured,
      tags: tags,
      accessibilityInfo: accessibilityInfo,
      promoterName: promoterName,
      locale: locale,
    );
  }

  Future<void> deleteEvent(int eventId) {
    return api.deleteEvent(eventId);
  }

  Future<EventReservationSummary> getEventReservationSummary(int eventId) {
    return api.getEventReservationSummary(eventId);
  }

  Future<PagedResponse<ManageableEventAttendeePreview>>
      getManageableEventAttendees({
    required int eventId,
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
  }) {
    return api.getManageableEventAttendees(
      eventId: eventId,
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }

  Future<void> removeAttendee(
    int eventId,
    int reservationId, {
    String? reason,
  }) {
    return api.removeAttendee(
      eventId,
      reservationId,
      reason: reason,
    );
  }

  Future<void> deleteEventImage({
    required int eventId,
    required int imageId,
  }) {
    return api.deleteEventImage(
      eventId: eventId,
      imageId: imageId,
    );
  }

  Future<void> addEventImage({
    required int eventId,
    required String imageUrl,
    required bool isCover,
  }) {
    return api.addEventImage(
      eventId: eventId,
      imageUrl: imageUrl,
      isCover: isCover,
    );
  }

  Future<List<String>> uploadEventImages(
    List<String> filePaths, {
    List<String?>? fileNames,
    List<Uint8List?>? bytesList,
  }) {
    return api.uploadEventImages(
      filePaths,
      fileNames: fileNames,
      bytesList: bytesList,
    );
  }

  Future<PagedResponse<AdminComment>> getEventComments({
  required int eventId,
  int page = 1,
  int pageSize = 20,
}) {
  return api.getEventComments(
    eventId: eventId,
    page: page,
    pageSize: pageSize,
  );
}

Future<PagedResponse<AdminComment>> getCommentReplies({
  required int commentId,
  int page = 1,
  int pageSize = 20,
}) {
  return api.getCommentReplies(
    commentId: commentId,
    page: page,
    pageSize: pageSize,
  );
}

Future<AdminComment> updateComment({
  required int commentId,
  required String content,
}) {
  return api.updateComment(
    commentId: commentId,
    content: content,
  );
}

Future<void> deleteComment({
  required int commentId,
}) {
  return api.deleteComment(
    commentId: commentId,
  );
}

  Future<String> uploadEventImage(
    String filePath, {
    String? fileName,
    Uint8List? bytes,
  }) {
    return api.uploadEventImage(
      filePath,
      fileName: fileName,
      bytes: bytes,
    );
  }
}