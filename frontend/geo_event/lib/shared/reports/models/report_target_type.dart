enum ReportTargetType {
  user('User'),
  event('Event'),
  comment('Comment'),
  review('Review');

  final String apiValue;

  const ReportTargetType(this.apiValue);

  String get displayName => apiValue;

  static ReportTargetType fromJson(String value) {
    return ReportTargetType.values.firstWhere(
      (type) => type.apiValue.toLowerCase() == value.toLowerCase(),
      orElse: () => ReportTargetType.event,
    );
  }
}