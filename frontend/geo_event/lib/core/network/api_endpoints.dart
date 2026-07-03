class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/health';

  static const authBase = '/api/auth';
  static const login = '$authBase/login';
  static const register = '$authBase/register';
  static const forgotPassword = '$authBase/forgot-password';
  static const resetPassword = '$authBase/reset-password';
  static const refresh = '$authBase/refresh';
  static const logout = '$authBase/logout';
  static const revokeAllSessions = '$authBase/revoke-all';

  static const usersBase = '/api/users';
  static const me = '$usersBase/me';
  static const currentUser = me;
  static const changePassword = '$usersBase/me/password';
  static const commentProfiles = '$usersBase/profiles';
  static const publicUsers = '$usersBase/public';
  static const payPalStatus = '$usersBase/me/paypal/status';

  static String publicUser(int userId) => '$usersBase/$userId/public';
  static String userReviews(int userId) => '$usersBase/$userId/reviews';
  static String rateUser(int userId) => '$usersBase/$userId/rating';
  static String banUser(int userId) => '$usersBase/$userId/ban';
  static String unbanUser(int userId) => '$usersBase/$userId/unban';

  static const preferencesBase = '/api/preferences';
  static const preferences = preferencesBase;
  static String preferencesForUser(int userId) =>
      '$preferencesBase/users/$userId';

  static const reportsBase = '/api/reports';
  static const myReports = '$reportsBase/my';
  static String reportById(int reportId) => '$reportsBase/$reportId';
  static String resolveReport(int reportId) => '$reportsBase/$reportId/resolve';

  static const publicEventsBase = '/api/public/events';
  static String publicEventById(int eventId) => '$publicEventsBase/$eventId';

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

  static const bookmarksBase = '/api/bookmarks';
  static const bookmarks = bookmarksBase;
  static String bookmarkById(int bookmarkId) => '$bookmarksBase/$bookmarkId';

  static const commentsBase = '/api/comments';
  static String commentsForEvent(int eventId) => '$commentsBase/event/$eventId';
  static String commentById(int commentId) => '$commentsBase/$commentId';
  static String commentReplies(int commentId) =>
      '$commentsBase/$commentId/replies';
  static String likeComment(int commentId) => '$commentsBase/$commentId/like';

  static const segmentsBase = '/api/segments';
  static const segments = segmentsBase;
  static String segmentById(int segmentId) => '$segmentsBase/$segmentId';
  static String genresForSegment(int segmentId) =>
      '$segmentsBase/$segmentId/genres';

  static const genresBase = '/api/genres';
  static String genreById(int genreId) => '$genresBase/$genreId';
  static String subGenresForGenre(int genreId) =>
      '$genresBase/$genreId/subgenres';

  static const uploadsBase = '/api/uploads';
  static const uploadImage = '$uploadsBase/images';

  static const ticketsBase = '/api/tickets';
  static const validateTicket = '$ticketsBase/validate';
  static String ticketById(int ticketId) => '$ticketsBase/$ticketId';

  static String eventTickets(int eventId) => '/api/events/$eventId/tickets';
  static String eventTicketById(int eventId, int eventTicketId) =>
      '/api/events/$eventId/tickets/$eventTicketId';

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

  static String refundReservation(int reservationId) =>
      '$reservationsBase/$reservationId/refund';

  static String requestRefund(int reservationId) =>
      '$reservationsBase/$reservationId/refund-request';

  static String reservationTickets(int reservationId) =>
      '$reservationsBase/$reservationId/tickets';

  static String reservationPayments(int reservationId) =>
      '$reservationsBase/$reservationId/payments';

  static String createPayPalOrder(int reservationId) =>
      '$reservationsBase/$reservationId/paypal-order';

  static String capturePayPalOrder(int reservationId) =>
      '$reservationsBase/$reservationId/paypal-capture';

  static String publicEventAttendees(int eventId) =>
      '$reservationsBase/public/events/$eventId/attendees';

  static String eventReservations(int eventId) =>
      '$reservationsBase/events/$eventId/reservations';

  static String removeEventReservation(int eventId, int reservationId) =>
      '$reservationsBase/events/$eventId/reservations/$reservationId/remove';
  
  static String collectReservationCash(int eventId, int reservationId) =>
    '$reservationsBase/events/$eventId/reservations/$reservationId/collect-cash';

  static String eventReservationSummary(int eventId) =>
      '$reservationsBase/events/$eventId/summary';

  static const notificationsBase = '/api/notifications';
  static const notifications = notificationsBase;
  static const unreadNotificationsCount = '$notificationsBase/unread-count';
  static const markAllNotificationsRead = '$notificationsBase/read-all';

  static String notificationById(int notificationId) =>
      '$notificationsBase/$notificationId';

  static String markNotificationRead(int notificationId) =>
      '$notificationsBase/$notificationId/read';

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