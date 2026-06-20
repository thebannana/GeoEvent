public class EventAuthorizationService : IEventAuthorizationService
{
    public Task<bool> CanManageEventAsync(int eventId, int userId, string role)
    {
        var isAdmin = string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase);
        return Task.FromResult(isAdmin);
    }
}