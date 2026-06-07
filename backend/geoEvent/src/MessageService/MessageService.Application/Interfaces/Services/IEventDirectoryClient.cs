using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IEventDirectoryClient
{
    Task<EventSummaryDto?> GetEventAsync(int eventId, CancellationToken cancellationToken = default);
}