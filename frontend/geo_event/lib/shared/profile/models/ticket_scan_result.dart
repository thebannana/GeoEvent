class TicketScanResultDto {
  final bool isValid;
  final String status;
  final String message;
  final int? ticketId;
  final int? reservationId;
  final int? eventId;
  final int? userId;
  final String? ticketType;
  final String? participantUsername;
  final String? participantAvatarUrl;
  final DateTime? issuedAt;
  final DateTime? usedAt;
  final DateTime? scannedAt;

  const TicketScanResultDto({
    required this.isValid,
    required this.status,
    required this.message,
    required this.ticketId,
    required this.reservationId,
    required this.eventId,
    required this.userId,
    required this.ticketType,
    required this.participantUsername,
    required this.participantAvatarUrl,
    required this.issuedAt,
    required this.usedAt,
    required this.scannedAt,
  });

  factory TicketScanResultDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return TicketScanResultDto(
      isValid: json['isValid'] == true,
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      ticketId: (json['ticketId'] as num?)?.toInt(),
      reservationId: (json['reservationId'] as num?)?.toInt(),
      eventId: (json['eventId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      ticketType: json['ticketType']?.toString(),
      participantUsername: json['participantUsername']?.toString(),
      participantAvatarUrl: json['participantAvatarUrl']?.toString(),
      issuedAt: parseDate(json['issuedAt']),
      usedAt: parseDate(json['usedAt']),
      scannedAt: parseDate(json['scannedAt']),
    );
  }
}