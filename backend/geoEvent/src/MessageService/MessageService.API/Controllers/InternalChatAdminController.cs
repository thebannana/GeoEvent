using MessageService.API.Contracts;
using MessageService.API.Filters;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace MessageService.API.Controllers;

[ApiController]
[Route("api/internal/chat")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public sealed class InternalChatAdminController : ControllerBase
{
    private readonly IChatService _chatService;

    public InternalChatAdminController(IChatService chatService)
    {
        _chatService = chatService;
    }

    [HttpPost("event-thread/add-user")]
    public async Task<IActionResult> AddUserToEventThread([FromBody] AddUserToEventThreadRequest request)
    {
        await _chatService.AddUserToEventThreadAsync(request.EventId, request.UserId, request.AddedByUserId);
        return Ok(new { message = "User added to event thread." });
    }

    [HttpPost("event-thread/remove-user")]
    public async Task<IActionResult> RemoveUserFromEventThread([FromBody] RemoveUserFromEventThreadRequest request)
    {
        await _chatService.RemoveUserFromEventThreadAsync(request.EventId, request.UserId);
        return Ok(new { message = "User removed from event thread." });
    }

    [HttpPost("users/handle-deleted")]
    public async Task<IActionResult> HandleDeletedUser([FromBody] HandleDeletedUserRequest request)
    {
        await _chatService.HandleDeletedUserAsync(request.UserId);
        return Ok(new { message = "Deleted user handled." });
    }
}