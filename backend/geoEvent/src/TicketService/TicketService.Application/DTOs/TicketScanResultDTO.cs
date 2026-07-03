namespace TicketService.Application.DTOs;

public class TicketScanResultDto
{
    public bool IsValid { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;

    public int? TicketId { get; set; }
    public int? ReservationId { get; set; }
    public int? EventId { get; set; }
    public int? UserId { get; set; }

    public string? TicketType { get; set; }
    public string? ParticipantUsername { get; set; }
    public string? ParticipantAvatarUrl { get; set; }

    public DateTime? IssuedAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime ScannedAt { get; set; }

    public string? PaymentMethod { get; set; }
    public string? PaymentStatus { get; set; }
    public string? PaymentMessage { get; set; }
}