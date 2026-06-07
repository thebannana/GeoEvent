namespace TicketService.Application.DTOs;

public class EventReservationSummaryResponseDto
{
    public int EventId { get; set; }
    public int Capacity { get; set; }
    public int ReservedCount { get; set; }
    public int ConfirmedCount { get; set; }
    public int PendingCount { get; set; }
    public int AvailableCount { get; set; }
    public int ReservationCount { get; set; }
    public bool IsSoldOut { get; set; }
}