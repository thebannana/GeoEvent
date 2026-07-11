namespace UserService.Application.Interfaces;

public interface IEventInternalClient
{
    Task<int> GetOrganizerEventsCountAsync(int userId, CancellationToken cancellationToken = default);
}