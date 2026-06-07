class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '/health';

  static const String authBase = '/api/auth';
  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String refresh = '$authBase/refresh';
  static const String logout = '$authBase/logout';

  static const String usersBase = '/api/users';
  static const String me = '$usersBase/me';
  static String userById(int userId) => '$usersBase/$userId';

  static const String preferencesBase = '/api/preferences';
  static const String preferences = preferencesBase;

  static const String eventsBase = '/api/events';
  static const String events = eventsBase;
  static const String eventTaxonomy = '$eventsBase/taxonomy';
  static const String eventSegments = '$eventsBase/segments';
  static const String eventGenres = '$eventsBase/genres';
  static const String eventSubGenres = '$eventsBase/subgenres';
  static String eventById(int eventId) => '$eventsBase/$eventId';
  static String eventImages(int eventId) => '$eventsBase/$eventId/images';

  static const String uploadsBase = '/api/uploads';
  static const String uploadImage = '$uploadsBase/images';

  static const String bookmarksBase = '/api/bookmarks';
  static const String bookmarks = bookmarksBase;

  static const String chatBase = '/api/chat';
  static const String conversations = '$chatBase/conversations';
  static const String messages = '$chatBase/messages';
  static String conversationMessages(String conversationId) =>
      '$conversations/$conversationId/messages';

  static const String notificationsBase = '/api/notifications';
  static const String notifications = notificationsBase;

  static const String reservationsBase = '/api/reservations';
  static const String reservations = reservationsBase;
  static String reservationById(int reservationId) =>
      '$reservationsBase/$reservationId';

  static const String reportsBase = '/api/reports';
  static const String reports = reportsBase;
}