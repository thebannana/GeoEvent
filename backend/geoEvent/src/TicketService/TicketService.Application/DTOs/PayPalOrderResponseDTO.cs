namespace TicketService.Application.DTOs;
public class PayPalOrderResponseDto
{
    public string OrderId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ApproveLink { get; set; } = string.Empty;
}
