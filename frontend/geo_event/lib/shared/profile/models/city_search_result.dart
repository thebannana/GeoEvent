class CitySearchResult {
  final int cityId;
  final String cityName;
  final String? countryName;
  final String? divisionName;

  const CitySearchResult({
    required this.cityId,
    required this.cityName,
    required this.countryName,
    required this.divisionName,
  });

  String get displayLabel {
    final parts = [
      cityName,
      if ((divisionName ?? '').trim().isNotEmpty) divisionName,
      if ((countryName ?? '').trim().isNotEmpty) countryName,
    ];

    return parts.join(', ');
  }

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
      cityName: (json['cityName'] ?? '').toString(),
      countryName: json['countryName']?.toString(),
      divisionName: json['divisionName']?.toString(),
    );
  }
}