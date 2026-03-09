using MessageService.API.Extensions;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MessageService.API.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class MessagesController : ControllerBase
{
    private readonly IMessageService _messageService;

    public MessagesController(IMessageService messageService)
    {
        _messageService = messageService;
    }

    [HttpPost]
    public async Task<IActionResult> Send([FromBody] SendMessageDto dto)
    {
        var userId = User.GetUserId();
        var result = await _messageService.SendMessageAsync(userId, dto);
        return result.Success
            ? CreatedAtAction(nameof(GetConversation), new { otherUserId = dto.RecipientId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("inbox")]
    public async Task<IActionResult> GetInbox([FromQuery] MessageFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _messageService.GetInboxAsync(userId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("sent")]
    public async Task<IActionResult> GetSent([FromQuery] MessageFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _messageService.GetSentAsync(userId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("conversation/{otherUserId:int}")]
    public async Task<IActionResult> GetConversation(int otherUserId, [FromQuery] MessageFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _messageService.GetConversationAsync(userId, otherUserId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{messageId:int}/read")]
    public async Task<IActionResult> MarkAsRead(int messageId)
    {
        var userId = User.GetUserId();
        var result = await _messageService.MarkAsReadAsync(messageId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = User.GetUserId();
        var result = await _messageService.GetUnreadCountAsync(userId);
        return result.Success
            ? Ok(new { unreadCount = result.Data })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{messageId:int}")]
    public async Task<IActionResult> Delete(int messageId)
    {
        var userId = User.GetUserId();
        var result = await _messageService.DeleteMessageAsync(messageId, userId);
        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
