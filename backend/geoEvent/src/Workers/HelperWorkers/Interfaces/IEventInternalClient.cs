using GeoEvent.HelperWorkers.DTOs;

namespace GeoEvent.HelperWorkers.Interfaces;

public interface IEventInternalClient
{
    Task<IReadOnlyList<EventLifecycleCandidateDto>>
        GetReadyToCompleteAsync(
            DateTime now,
            CancellationToken cancellationToken = default);

    Task CompleteAsync(
        int eventId,
        CancellationToken cancellationToken = default);
}