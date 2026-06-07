class MapboxCitySearchResult {
  final String mapboxId;
  final String cityName;
  final String? regionName;
  final String? countryName;
  final double latitude;
  final double longitude;

  const MapboxCitySearchResult({
    required this.mapboxId,
    required this.cityName,
    required this.regionName,
    required this.countryName,
    required this.latitude,
    required this.longitude,
  });

  String get displayLabel {
    final parts = [
      cityName,
      if ((regionName ?? '').trim().isNotEmpty) regionName,
      if ((countryName ?? '').trim().isNotEmpty) countryName,
    ];
    return parts.join(', ');
  }
}