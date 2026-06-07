namespace MessageService.Application.Interfaces.Services;

public interface IUserPresenceTracker
{
    Task SetOnlineAsync(int userId);
    Task SetOfflineAsync(int userId);
    Task<bool> IsOnlineAsync(int userId);
    Task<DateTime?> GetLastActiveAtAsync(int userId);
}