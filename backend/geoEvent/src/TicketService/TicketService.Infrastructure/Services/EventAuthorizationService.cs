public class EventAuthorizationService : IEventAuthorizationService
{
    public Task<bool> CanManageEventAsync(int eventId, int userId, string role)
    {
        if (string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(true);
        }

        return Task.FromResult(true); // temporary stub, replace with real ownership check
    }
}