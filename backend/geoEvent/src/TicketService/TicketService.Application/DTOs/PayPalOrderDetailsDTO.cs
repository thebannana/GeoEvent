namespace TicketService.Application.DTOs;
public class PayPalOrderDetailsDto
{
    public string OrderId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string ReferenceId { get; set; } = string.Empty;
}
