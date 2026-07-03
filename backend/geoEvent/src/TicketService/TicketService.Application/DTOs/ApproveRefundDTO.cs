namespace TicketService.Application.DTOs;

public class ApproveRefundDto
{
    public decimal? Amount { get; set; }
    public string? DecisionReason { get; set; }
}