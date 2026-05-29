using MessageService.API.Hubs;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.SignalR;

namespace MessageService.API.Realtime;

public class SignalRMessageRealtimeNotifier : IMessageRealtimeNotifier
{
    private readonly IHubContext<MessageHub> _hubContext;

    public SignalRMessageRealtimeNotifier(IHubContext<MessageHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task MessageCreatedAsync(MessageResponseDto message, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageCreated", message, senderId, recipientId);
    }

    public async Task MessageUpdatedAsync(MessageResponseDto message, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageUpdated", message, senderId, recipientId);
    }

    public async Task MessageLikedAsync(MessageResponseDto message, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageLiked", message, senderId, recipientId);
    }

    public async Task MessageUnlikedAsync(MessageResponseDto message, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageUnliked", message, senderId, recipientId);
    }

    public async Task MessageReadAsync(MessageResponseDto message, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageRead", message, senderId, recipientId);
    }

    public async Task MessageDeletedAsync(int messageId, int senderId, int recipientId)
    {
        await BroadcastToParticipants("MessageDeleted", new { messageId }, senderId, recipientId);
    }

    public async Task ConversationReadAllAsync(int readerUserId, int otherUserId)
    {
        await _hubContext.Clients
            .Group(MessageHub.UserGroup(otherUserId))
            .SendAsync("ConversationReadAll", new
            {
                readerUserId,
                otherUserId
            });
    }

    private async Task BroadcastToParticipants(string eventName, object payload, int senderId, int recipientId)
    {
        await _hubContext.Clients
            .Group(MessageHub.UserGroup(senderId))
            .SendAsync(eventName, payload);

        if (recipientId != senderId)
        {
            await _hubContext.Clients
                .Group(MessageHub.UserGroup(recipientId))
                .SendAsync(eventName, payload);
        }
    }
}