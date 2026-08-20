import '../../../core/utils/json_helpers.dart';

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
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentMessage;

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
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentMessage,
  });

  factory TicketScanResultDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      return JsonHelpers.parseDateTime(value);
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
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentMessage: json['paymentMessage']?.toString(),
    );
  }
}