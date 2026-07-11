using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Interfaces;

public interface ITicketInternalClient
{
    Task CreateDefaultTicketForEventAsync(
        EventCreatedMessage message,
        CancellationToken cancellationToken = default);
}