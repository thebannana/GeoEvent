public interface IEventAuthorizationService
{
    Task<bool> CanManageEventAsync(int eventId, int userId, string role);
}