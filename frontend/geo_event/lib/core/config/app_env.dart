class AppEnv {
  static const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static void validate() {
    if (mapboxToken.isEmpty) {
      throw Exception(
        'MAPBOX_ACCESS_TOKEN is missing. Run Flutter with --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }
  }
}