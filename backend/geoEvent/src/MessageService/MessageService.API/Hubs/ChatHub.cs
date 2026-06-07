using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using MessageService.Application.Interfaces.Services;
using System.Security.Claims;

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
        var userId = GetUserId();
        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
        await _chatService.SetUserOnlineAsync(userId, true);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        await _chatService.SetUserOnlineAsync(userId, false);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, UserGroup(userId));
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinThread(long threadId)
    {
        var userId = GetUserId();
        var isParticipant = await _chatService.IsParticipantAsync(threadId, userId);
        if (!isParticipant)
            throw new HubException("You are not a participant of this thread.");

        await Groups.AddToGroupAsync(Context.ConnectionId, ThreadGroup(threadId));
    }

    public async Task LeaveThread(long threadId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, ThreadGroup(threadId));
    }

    private int GetUserId()
    {
        var raw = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? Context.User?.FindFirst("sub")?.Value;

        return int.Parse(raw!);
    }
}