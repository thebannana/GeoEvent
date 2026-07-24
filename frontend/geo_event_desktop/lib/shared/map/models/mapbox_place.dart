class MapboxPlace {
  final String id;
  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;

  const MapboxPlace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}