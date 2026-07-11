using MessageService.API.Extensions;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace MessageService.API.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly IChatService _chatService;

    public ChatHub(IChatService chatService)
    {
        _chatService = chatService;
    }

    public static string UserGroup(int userId) => $"user:{userId}";
    public static string ThreadGroup(long threadId) => $"thread:{threadId}";

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.GetUserId()
            ?? throw new HubException("User is not authenticated.");

        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
        await _chatService.SetUserOnlineAsync(userId, true);

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.GetUserId();
        if (userId.HasValue)
        {
            await _chatService.SetUserOnlineAsync(userId.Value, false);
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, UserGroup(userId.Value));
        }

        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinThread(long threadId)
    {
        var userId = Context.User?.GetUserId()
            ?? throw new HubException("User is not authenticated.");

        var isParticipant = await _chatService.IsParticipantAsync(threadId, userId);
        if (!isParticipant)
            throw new HubException("You are not a participant of this thread.");

        await Groups.AddToGroupAsync(Context.ConnectionId, ThreadGroup(threadId));
    }

    public async Task LeaveThread(long threadId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, ThreadGroup(threadId));
    }
}