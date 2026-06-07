class EventDirectionsRequest {
  final int eventId;
  final double latitude;
  final double longitude;
  final String title;

  const EventDirectionsRequest({
    required this.eventId,
    required this.latitude,
    required this.longitude,
    required this.title,
  });
}