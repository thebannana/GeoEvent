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

        await ThreadUpdatedAsync(message.ThreadId, participantUserIds);
    }

    public async Task MessageUpdatedAsync(ChatMessageDto message, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(message.ThreadId))
            .SendAsync("MessageUpdated", message);

        await ThreadUpdatedAsync(message.ThreadId, participantUserIds);
    }

    public async Task MessageDeletedAsync(long threadId, long messageId, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(threadId))
            .SendAsync("MessageDeleted", new { threadId, messageId });

        await ThreadUpdatedAsync(threadId, participantUserIds);
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

        await ThreadUpdatedAsync(threadId, participantUserIds);
    }

    public async Task ThreadUpdatedAsync(long threadId, IReadOnlyCollection<int> participantUserIds)
    {
        foreach (var userId in participantUserIds)
        {
            await _hub.Clients.Group(ChatHub.UserGroup(userId))
                .SendAsync("ThreadUpdated", new { threadId });
        }
    }

    public async Task ParticipantLeftAsync(long threadId, int userId, IReadOnlyCollection<int> participantUserIds)
    {
        await _hub.Clients.Group(ChatHub.ThreadGroup(threadId))
            .SendAsync("ParticipantLeft", new { threadId, userId });

        await ThreadUpdatedAsync(threadId, participantUserIds);
    }
}