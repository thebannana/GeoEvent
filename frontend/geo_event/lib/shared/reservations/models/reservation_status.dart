enum ReservationStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  cancelled('Cancelled'),
  expired('Expired'),
  refunded('Refunded'),
  unknown('Unknown');

  final String apiValue;

  const ReservationStatus(this.apiValue);

  static ReservationStatus fromJson(String? value) {
    if (value == null) return ReservationStatus.unknown;

    for (final status in ReservationStatus.values) {
      if (status.apiValue.toLowerCase() == value.toLowerCase()) {
        return status;
      }
    }

    return ReservationStatus.unknown;
  }
}