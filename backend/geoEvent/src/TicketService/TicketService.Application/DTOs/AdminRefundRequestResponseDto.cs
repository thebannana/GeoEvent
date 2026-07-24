namespace TicketService.Application.DTOs;

public class AdminRefundRequestResponseDto
{
    public int ReservationId { get; set; }
    public string RefundRequestId { get; set; } = string.Empty;

    public int EventId { get; set; }
    public string EventTitle { get; set; } = string.Empty;
    public string? EventImageUrl { get; set; }

    public int UserId { get; set; }
    public string RequesterName { get; set; } = string.Empty;
    public string RequesterUsername { get; set; } = string.Empty;
    public string? RequesterAvatarUrl { get; set; }

    public string TargetName { get; set; } = string.Empty;
    public string TargetUsername { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;
    public string Preview { get; set; } = string.Empty;
    public string FullContent { get; set; } = string.Empty;

    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public string AmountLabel { get; set; } = string.Empty;

    public RefundQueueStatus QueueStatus { get; set; }
    public string RefundRequestStatus { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? RequestedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public int? ReviewedByUserId { get; set; }
    public string? DecisionReason { get; set; }
    public string? ModeratorAction { get; set; }

    public string? PaymentMethod { get; set; }
    public string? PaymentStatus { get; set; }
}