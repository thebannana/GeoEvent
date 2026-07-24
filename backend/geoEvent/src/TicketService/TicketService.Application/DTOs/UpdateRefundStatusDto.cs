using System.ComponentModel.DataAnnotations;

namespace TicketService.Application.DTOs;

public class UpdateRefundStatusDto
{
    [Required]
    public string Status { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? DecisionReason { get; set; }

    [MaxLength(255)]
    public string? RefundTransactionId { get; set; }
}