using UserService.Application.DTOs;

namespace UserService.Application.Interfaces;

public interface IEventInternalClient
{
    Task<int> GetOrganizerEventsCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<List<EventSegmentLookupDto>> GetAllSegmentsAsync(CancellationToken cancellationToken = default);
    Task<InternalEventEngagementStatsDto> GetEngagementStatsAsync(CancellationToken cancellationToken = default);
}