using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface IInternalEventLookupClient
{
    Task<EventSummaryDto?> GetEventAsync(int eventId, CancellationToken cancellationToken = default);
}