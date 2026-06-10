using MessageService.API.Hubs;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.SignalR;

namespace MessageService.API.Realtime;

public class SignalRChatRealtimeNotifier : IChatRealtimeNotifier
{
    private readonly IHubContext<ChatHub> _hub;

    public SignalRChatRealtimeNotifier(IHubContext<ChatHub> hub)
    {
        _hub = hub;
    }

    public async Task MessageCreatedAsync(ChatMessageDto message, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(message.ThreadId))
            .SendAsync("MessageCreated", message);

        foreach (var userId in participantUserIds)
        {
            await _hub.Clients.Group(ChatHub.UserGroup(userId))
                .SendAsync("ThreadUpdated", new { threadId = message.ThreadId });
        }
    }

    public async Task MessageUpdatedAsync(ChatMessageDto message, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(message.ThreadId))
            .SendAsync("MessageUpdated", message);

        foreach (var userId in participantUserIds)
        {
            await _hub.Clients.Group(ChatHub.UserGroup(userId))
                .SendAsync("ThreadUpdated", new { threadId = message.ThreadId });
        }
    }

    public async Task MessageDeletedAsync(long threadId, long messageId, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(threadId))
            .SendAsync("MessageDeleted", new { threadId, messageId });

        foreach (var userId in participantUserIds)
        {
            await _hub.Clients.Group(ChatHub.UserGroup(userId))
                .SendAsync("ThreadUpdated", new { threadId });
        }
    }

    public async Task MessageLikedAsync(ChatMessageDto message)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(message.ThreadId))
            .SendAsync("MessageLiked", message);
    }

    public async Task ThreadReadAsync(long threadId, int userId, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(threadId))
            .SendAsync("ThreadRead", new { threadId, userId });

        foreach (var participantUserId in participantUserIds)
        {
            await _hub.Clients.Group(ChatHub.UserGroup(participantUserId))
                .SendAsync("ThreadUpdated", new { threadId });
        }
    }
}