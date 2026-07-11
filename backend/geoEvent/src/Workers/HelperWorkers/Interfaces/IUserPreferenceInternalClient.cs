using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Interfaces;

public interface IUserPreferenceInternalClient
{
    Task ApplyInteractionPreferenceAsync(
        UserEventPreferenceInteractionMessage message,
        CancellationToken cancellationToken = default);
}