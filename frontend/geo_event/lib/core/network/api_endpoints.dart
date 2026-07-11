class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/health';

  // =========================
  // Auth
  // =========================
  static const authBase = '/api/auth';
  static const login = '$authBase/login';
  static const register = '$authBase/register';
  static const forgotPassword = '$authBase/forgot-password';
  static const resetPassword = '$authBase/reset-password';
  static const refresh = '$authBase/refresh';
  static const logout = '$authBase/logout';
  static const revokeAllSessions = '$authBase/revoke-all';

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

  // =========================
  // Preferences
  // =========================
  static const preferencesBase = '/api/preferences';
  static const preferences = preferencesBase;

  static String preferencesForUser(int userId) =>
      '$preferencesBase/users/$userId';

  // =========================
  // Reports
  // =========================
  static const reportsBase = '/api/reports';
  static const myReports = '$reportsBase/my';

  static String reportById(int reportId) => '$reportsBase/$reportId';
  static String resolveReport(int reportId) =>
      '$reportsBase/$reportId/resolve';

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
  static const commentsBase = '/api/comments';

  static String commentsForEvent(int eventId) => '$commentsBase/event/$eventId';
  static String commentById(int commentId) => '$commentsBase/$commentId';
  static String commentReplies(int commentId) =>
      '$commentsBase/$commentId/replies';
  static String likeComment(int commentId) => '$commentsBase/$commentId/like';

  // =========================
  // Segments
  // =========================
  static const segmentsBase = '/api/segments';
  static const segments = segmentsBase;

  static String segmentById(int segmentId) => '$segmentsBase/$segmentId';

  static String genresForSegment(int segmentId) =>
      '$segmentsBase/$segmentId/genres';

  // =========================
  // Genres
  // =========================
  static const genresBase = '/api/genres';

  static String genreById(int genreId) => '$genresBase/$genreId';

  static String subGenresForGenre(int genreId) =>
      '$genresBase/$genreId/subgenres';

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
  static const reservationsBase = '/api/reservations';
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

  static String requestRefund(int reservationId) =>
      '$reservationsBase/$reservationId/refund-request';

  static String reservationTickets(int reservationId) =>
      '$reservationsBase/$reservationId/tickets';

  static String reservationPayments(int reservationId) =>
      '$reservationsBase/$reservationId/payments';

  static String publicEventAttendees(int eventId) =>
      '$reservationsBase/public/events/$eventId/attendees';

  static String eventReservations(int eventId) =>
      '$reservationsBase/events/$eventId/reservations';

  static String removeEventReservation(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/remove';

  static String collectReservationCash(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/collect-cash';

  static String approveRefund(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/approve-refund';

  static String rejectRefund(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/reject-refund';

  static String eventReservationSummary(int eventId) =>
      '$reservationsBase/events/$eventId/summary';

  // =========================
  // Reservation Payments
  // =========================
  static String createPayPalOrder(int reservationId) =>
      '$reservationsBase/$reservationId/payments/paypal-order';

  static String capturePayPalOrder(int reservationId) =>
      '$reservationsBase/$reservationId/payments/paypal-capture';

  // =========================
  // Notifications
  // =========================
  static const notificationsBase = '/api/notifications';
  static const notifications = notificationsBase;
  static const unreadNotificationsCount = '$notificationsBase/unread-count';
  static const markAllNotificationsRead = '$notificationsBase/read-all';

  static String notificationById(int notificationId) =>
      '$notificationsBase/$notificationId';

  static String markNotificationRead(int notificationId) =>
      '$notificationsBase/$notificationId/read';

  // =========================
  // Chat
  // =========================
  static const chatBase = '/api/chat';
  static const threads = '$chatBase/threads';
  static const unreadChatCount = '$chatBase/unread-count';
  static const openDirectThread = '$chatBase/threads/direct/open';

  static String threadById(int threadId) => '$chatBase/threads/$threadId';

  static String threadMessages(int threadId) =>
      '$chatBase/threads/$threadId/messages';

  static String threadParticipants(int threadId) =>
      '$chatBase/threads/$threadId/participants';

  static String markThreadRead(int threadId) =>
      '$chatBase/threads/$threadId/read';

  static String leaveThread(int threadId) => '$chatBase/threads/$threadId';

  static String messageById(int messageId) => '$chatBase/messages/$messageId';

  static String likeMessage(int messageId) =>
      '$chatBase/messages/$messageId/like';

  static const chatHub = '/hubs/chat';
}