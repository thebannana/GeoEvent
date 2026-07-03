namespace TicketService.Application.DTOs;
public class PayPalRefundResponseDto
{
    public string RefundId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
