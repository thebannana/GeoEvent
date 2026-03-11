using TicketService.Domain.Enums;

namespace TicketService.Application.DTOs;

public class ReservationFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public ReservationStatus? Status { get; set; }
    public int? EventId { get; set; }
}
