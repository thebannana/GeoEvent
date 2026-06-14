using MessageService.API.Extensions;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MessageService.API.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;

    public ChatController(IChatService chatService)
    {
        _chatService = chatService;
    }

    [HttpPost("threads/direct/open")]
    public async Task<IActionResult> OpenDirect([FromBody] OpenDirectThreadDto dto)
    {
        var userId = User.GetUserId();
        var result = await _chatService.OpenDirectThreadAsync(userId, dto.OtherUserId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("threads")]
    public async Task<IActionResult> GetThreads()
    {
        var userId = User.GetUserId();
        var result = await _chatService.GetThreadsAsync(userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("threads/{threadId:long}")]
    public async Task<IActionResult> GetThread(long threadId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.GetThreadDetailAsync(threadId, userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("threads/{threadId:long}/messages")]
    public async Task<IActionResult> GetMessages(long threadId, [FromQuery] int page = 1, [FromQuery] int pageSize = 30)
    {
        var userId = User.GetUserId();
        var result = await _chatService.GetMessagesAsync(threadId, userId, page, pageSize);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("threads/{threadId:long}/messages")]
    public async Task<IActionResult> SendMessage(long threadId, [FromBody] SendThreadMessageDto dto)
    {
        var userId = User.GetUserId();
        var result = await _chatService.SendMessageAsync(threadId, userId, dto);
        return result.Success ? StatusCode(StatusCodes.Status201Created, result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("messages/{messageId:long}")]
    public async Task<IActionResult> EditMessage(long messageId, [FromBody] EditChatMessageDto dto)
    {
        var userId = User.GetUserId();
        var result = await _chatService.EditMessageAsync(messageId, userId, dto);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("messages/{messageId:long}")]
    public async Task<IActionResult> DeleteMessage(long messageId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.DeleteMessageAsync(messageId, userId);
        return result.Success ? NoContent() : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("messages/{messageId:long}/like")]
    public async Task<IActionResult> LikeMessage(long messageId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.LikeMessageAsync(messageId, userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("messages/{messageId:long}/like")]
    public async Task<IActionResult> UnlikeMessage(long messageId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.UnlikeMessageAsync(messageId, userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("threads/{threadId:long}/read")]
    public async Task<IActionResult> MarkThreadRead(long threadId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.MarkThreadReadAsync(threadId, userId);
        return result.Success ? Ok(new { message = "Thread marked as read." }) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = User.GetUserId();
        var result = await _chatService.GetUnreadCountAsync(userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("threads/{threadId:long}/participants")]
    public async Task<IActionResult> GetParticipants(long threadId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.GetParticipantsAsync(threadId, userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("threads/{threadId:long}")]
    public async Task<IActionResult> LeaveThread(long threadId)
    {
        var userId = User.GetUserId();
        var result = await _chatService.LeaveThreadAsync(threadId, userId);
        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}