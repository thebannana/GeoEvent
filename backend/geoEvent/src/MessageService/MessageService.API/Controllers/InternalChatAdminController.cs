using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace MessageService.API.Controllers;

[ApiController]
[Route("api/internal/chat")]
public class InternalChatAdminController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly IConfiguration _configuration;

    public InternalChatAdminController(IChatService chatService, IConfiguration configuration)
    {
        _chatService = chatService;
        _configuration = configuration;
    }

    private bool HasValidInternalApiKey()
    {
        var configuredKey = _configuration["InternalApi:Key"];
        if (string.IsNullOrWhiteSpace(configuredKey))
            return false;

        if (!Request.Headers.TryGetValue("X-Internal-Api-Key", out var providedKey))
            return false;

        return string.Equals(providedKey.ToString(), configuredKey, StringComparison.Ordinal);
    }

    [HttpPost("event-thread/add-user")]
    public async Task<IActionResult> AddUserToEventThread([FromBody] AddUserToEventThreadRequest request)
    {
        if (!HasValidInternalApiKey())
            return Unauthorized(new { error = "Invalid internal API key." });

        await _chatService.AddUserToEventThreadAsync(request.EventId, request.UserId, request.AddedByUserId);
        return Ok(new { message = "User added to event thread." });
    }

    [HttpPost("event-thread/remove-user")]
    public async Task<IActionResult> RemoveUserFromEventThread([FromBody] RemoveUserFromEventThreadRequest request)
    {
        if (!HasValidInternalApiKey())
            return Unauthorized(new { error = "Invalid internal API key." });

        await _chatService.RemoveUserFromEventThreadAsync(request.EventId, request.UserId);
        return Ok(new { message = "User removed from event thread." });
    }

    [HttpPost("users/handle-deleted")]
    public async Task<IActionResult> HandleDeletedUser([FromBody] HandleDeletedUserRequest request)
    {
        if (!HasValidInternalApiKey())
            return Unauthorized(new { error = "Invalid internal API key." });

        await _chatService.HandleDeletedUserAsync(request.UserId);
        return Ok(new { message = "Deleted user handled." });
    }
}

public sealed class AddUserToEventThreadRequest
{
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int? AddedByUserId { get; set; }
}

public sealed class RemoveUserFromEventThreadRequest
{
    public int EventId { get; set; }
    public int UserId { get; set; }
}

public sealed class HandleDeletedUserRequest
{
    public int UserId { get; set; }
}