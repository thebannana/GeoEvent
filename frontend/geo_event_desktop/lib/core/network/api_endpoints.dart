class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/health';

  // =========================
  // Auth
  // =========================
  static const authBase = '/api/auth';
  static const login = '$authBase/login';
  static const adminLogin = '$authBase/admin-login';
  static const register = '$authBase/register';
  static const forgotPassword = '$authBase/forgot-password';
  static const resetPassword = '$authBase/reset-password';
  static const refresh = '$authBase/refresh';
  static const logout = '$authBase/logout';
  static const revokeAllSessions = '$authBase/revoke-all';

  // =========================
  // Admin Dashboard
  // =========================
  static const adminDashboardBase = '/api/admin/dashboard';
  static const adminDashboardUsers = '$adminDashboardBase/users';
  static const adminDashboardEvents = '$adminDashboardBase/events';
  static const adminDashboardTickets = '$adminDashboardBase/tickets';

  // =========================
  // Admin Events
  // =========================
  static const adminEventsBase = '/api/admin/events';
  static const adminEvents = adminEventsBase;

  static String adminEvent(int eventId) => '$adminEventsBase/$eventId';

  static String adminEventImages(int eventId) => eventImages(eventId);

  static String adminEventImage(int eventId, int imageId) =>
      deleteEventImage(eventId, imageId);

  static String adminEventCoverImage(int eventId, int imageId) =>
      setEventCoverImage(eventId, imageId);

  // =========================
  // Users
  // =========================
  static const usersBase = '/api/users';
  static const me = '$usersBase/me';
  static const currentUser = me;
  static const changePassword = '$usersBase/me/password';
  static const commentProfiles = '$usersBase/profiles';
  static const publicUsers = '$usersBase/public';

  static String publicUser(int userId) => '$usersBase/$userId/public';
  static String userReviews(int userId) => '$usersBase/$userId/reviews';
  static String rateUser(int userId) => '$usersBase/$userId/rating';
  static String banUser(int userId) => '$usersBase/$userId/ban';
  static String unbanUser(int userId) => '$usersBase/$userId/unban';
  static String adminUser(int userId) => '$usersBase/$userId';
  static String adminUserProfile(int userId) => '$usersBase/$userId/admin-profile';

  // =========================
  // Preferences
  // =========================
  static const preferencesBase = '/api/preferences';
  static const preferences = preferencesBase;

  static String preferencesForUser(int userId) =>
      '$preferencesBase/users/$userId';

// =========================
// Reports / Moderation
// =========================
static const reportsBase = '/api/reports';
static const myReports = '$reportsBase/my';
static const adminReports = reportsBase;

static String reportById(int reportId) => '$reportsBase/$reportId';
static String updateReportStatus(int reportId) => '$reportsBase/$reportId/status';

// =========================
// Refund moderation
// =========================
static const reservationsBase = '/api/reservations';
static const adminRefundRequests = '$reservationsBase/refund-requests';

static String approveRefund({
  required int eventId,
  required int reservationId,
}) =>
    '$reservationsBase/events/$eventId/reservations/$reservationId/approve-refund';

static String rejectRefund({
  required int eventId,
  required int reservationId,
}) =>
    '$reservationsBase/events/$eventId/reservations/$reservationId/reject-refund';

  // =========================
  // Public Events
  // =========================
  static const publicEventsBase = '/api/public/events';
  static const publicEvents = publicEventsBase;
  static const nearbyPublicEvents = '$publicEventsBase/nearby';

  static String publicEventById(int eventId) => '$publicEventsBase/$eventId';

  // =========================
  // Events
  // =========================
  static const eventsBase = '/api/events';
  static const events = eventsBase;
  static const myEvents = '$eventsBase/mine';
  static const likedEvents = '$eventsBase/liked';

  static String eventById(int eventId) => '$eventsBase/$eventId';
  static String publishEvent(int eventId) => '$eventsBase/$eventId/publish';
  static String likeEvent(int eventId) => '$eventsBase/$eventId/like';
  static String cancelEvent(int eventId) => '$eventsBase/$eventId/cancel';
  static String completeEvent(int eventId) => '$eventsBase/$eventId/complete';

  static String eventImages(int eventId) => '$eventsBase/$eventId/images';

  static String deleteEventImage(int eventId, int imageId) =>
      '$eventsBase/$eventId/images/$imageId';

  static String setEventCoverImage(int eventId, int imageId) =>
      '$eventsBase/$eventId/images/$imageId/cover';

  // =========================
  // Bookmarks
  // =========================
  static const bookmarksBase = '/api/bookmarks';
  static const bookmarks = bookmarksBase;

  static String bookmarkById(int bookmarkId) => '$bookmarksBase/$bookmarkId';

  // =========================
  // Comments
  // =========================
static const String commentsBase = '/api/comments';
static String commentsByEvent(int eventId) => '/api/comments/event/$eventId';
static String commentReplies(int commentId) => '/api/comments/$commentId/replies';
static String commentById(int commentId) => '/api/comments/$commentId';

static const String adminCommentsBase = '/api/admin/comments';
static String adminCommentById(int commentId) => '/api/admin/comments/$commentId';

  // =========================
  // Segments
  // =========================
  static const segments = '/api/segments';
  static String segmentById(int id) => '$segments/$id';
  static String genresBySegment(int segmentId) => '$segments/$segmentId/genres';

  // =========================
  // Genres
  // =========================
  static const genres = '/api/genres';
  static String genreById(int id) => '$genres/$id';
  static String subGenresByGenre(int genreId) => '$genres/$genreId/subgenres';

  // =========================
  // Subgenres
  // =========================
  static const subGenres = '/api/subgenres';
  static String subGenreById(int id) => '$subGenres/$id';

  // =========================
  // Uploads
  // =========================
  static const uploadsBase = '/api/uploads';
  static const uploadImage = '$uploadsBase/images';

  // =========================
  // Tickets
  // =========================
  static const ticketsBase = '/api/tickets';
  static const myTickets = '$ticketsBase/my';
  static const validateTicket = '$ticketsBase/validate';

  static String ticketById(int ticketId) => '$ticketsBase/$ticketId';
  static String cancelTicket(int ticketId) => '$ticketsBase/$ticketId/cancel';

  static String eventTickets(int eventId) => '/api/events/$eventId/tickets';

  static String eventTicketById(int eventId, int eventTicketId) =>
      '/api/events/$eventId/tickets/$eventTicketId';

  // =========================
  // Reservations
  // =========================
  static const reservations = reservationsBase;
  static const myReservations = '$reservationsBase/my';

  static String reservationById(int reservationId) =>
      '$reservationsBase/$reservationId';

  static String confirmReservation(int reservationId) =>
      '$reservationsBase/$reservationId/confirm';

  static String cashConfirmReservation(int reservationId) =>
      '$reservationsBase/$reservationId/cash-confirm';

  static String cancelReservation(int reservationId) =>
      '$reservationsBase/$reservationId/cancel';

  static String reservationTickets(int reservationId) =>
      '$reservationsBase/$reservationId/tickets';

  static String reservationPayments(int reservationId) =>
      '$reservationsBase/$reservationId/payments';

  static String eventReservations(int eventId) =>
      '$reservationsBase/events/$eventId/reservations';

  static String eventReservationSummary(int eventId) =>
      '$reservationsBase/events/$eventId/summary';

  static String publicEventAttendees(int eventId) =>
      '$reservationsBase/public/events/$eventId/attendees';

  static String manageableEventAttendees(int eventId) =>
      '$reservationsBase/events/$eventId/attendees/manage';

  static String removeEventReservation(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/remove';

  static String collectReservationCash(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/collect-cash';
}