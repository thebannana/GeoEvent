using System.Collections.Concurrent;
using MessageService.Application.Interfaces.Services;

namespace MessageService.Infrastructure.Services;

public class InMemoryUserPresenceTracker : IUserPresenceTracker
{
    private static readonly ConcurrentDictionary<int, byte> OnlineUsers = new();
    private static readonly ConcurrentDictionary<int, DateTime> LastActive = new();

    public Task SetOnlineAsync(int userId)
    {
        OnlineUsers[userId] = 1;
        LastActive[userId] = DateTime.UtcNow;
        return Task.CompletedTask;
    }

    public Task SetOfflineAsync(int userId)
    {
        OnlineUsers.TryRemove(userId, out _);
        LastActive[userId] = DateTime.UtcNow;
        return Task.CompletedTask;
    }

    public Task<bool> IsOnlineAsync(int userId)
    {
        return Task.FromResult(OnlineUsers.ContainsKey(userId));
    }

    public Task<DateTime?> GetLastActiveAtAsync(int userId)
    {
        return Task.FromResult(
            LastActive.TryGetValue(userId, out var value)
                ? (DateTime?)value
                : null);
    }
}