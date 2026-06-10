namespace TicketService.Application.DTOs;

public class ValidateTicketScanDto
{
    public int EventId { get; set; }
    public string QrCode { get; set; } = string.Empty;
}