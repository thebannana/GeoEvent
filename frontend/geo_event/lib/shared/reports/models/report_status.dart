enum ReportStatus {
  pending('Pending'),
  underReview('UnderReview'),
  resolved('Resolved'),
  dismissed('Dismissed');

  final String apiValue;
  const ReportStatus(this.apiValue);

  static ReportStatus fromJson(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.apiValue.toLowerCase() == value.toLowerCase(),
      orElse: () => ReportStatus.pending,
    );
  }
}