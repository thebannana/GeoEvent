using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.Services;

public class EventAuthorizationService : IEventAuthorizationService
{
    private readonly IEventDirectoryClient _eventDirectoryClient;

    public EventAuthorizationService(IEventDirectoryClient eventDirectoryClient)
    {
        _eventDirectoryClient = eventDirectoryClient;
    }

    public async Task<bool> CanManageEventAsync(int eventId, int userId, string role)
    {
        if (eventId <= 0 || userId <= 0 || string.IsNullOrWhiteSpace(role))
            return false;

        if (string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
            return true;

        var eventSummary = await _eventDirectoryClient.GetEventAsync(eventId);
        if (eventSummary?.OrganizerId is null)
            return false;

        return eventSummary.OrganizerId.Value == userId;
    }
}