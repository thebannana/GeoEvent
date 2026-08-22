using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Interfaces;

public interface ITicketInternalClient
{
    Task CreateDefaultTicketForEventAsync(
        EventCreatedMessage message,
        CancellationToken cancellationToken = default);

    Task ExpireReservationsAsync(
    CancellationToken cancellationToken = default);

    Task ExpireEventDataAsync(
    int eventId,
    CancellationToken cancellationToken = default);
}