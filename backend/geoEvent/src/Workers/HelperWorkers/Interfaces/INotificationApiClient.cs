using GeoEvent.HelperWorkers.DTOs;

namespace GeoEvent.HelperWorkers.Interfaces;

public interface INotificationApiClient
{
    Task CreateNotificationAsync(CreateNotificationRequest request, CancellationToken cancellationToken = default);
}