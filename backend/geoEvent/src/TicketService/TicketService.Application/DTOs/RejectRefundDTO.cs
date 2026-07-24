namespace TicketService.Application.DTOs;

public class RejectRefundDto
{
    public string? DecisionReason { get; set; }
    public string? ModeratorAction { get; set; }
}