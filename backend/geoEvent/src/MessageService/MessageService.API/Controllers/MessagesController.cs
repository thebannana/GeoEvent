using MessageService.API.Extensions;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

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
    [EnableRateLimiting("send-message")]
    public async Task<IActionResult> Send([FromBody] SendMessageDto dto)
    {
        var userId = User.GetUserId();
        var result = await _messageService.SendMessageAsync(userId, dto);
        return result.Success
            ? StatusCode(StatusCodes.Status201Created, result.Data)
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
    public async Task<IActionResult> GetConversation(
    int otherUserId, [FromQuery] MessageFilterDto filter)
    {
        var userId = User.GetUserId();
        if (userId == otherUserId)
            return BadRequest(new { error = "Cannot retrieve conversation with yourself." });

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

    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var userId = User.GetUserId();
        var result = await _messageService.GetConversationSummariesAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("conversation/{otherUserId:int}/read-all")]
    public async Task<IActionResult> MarkAllAsRead(int otherUserId)
    {
        var userId = User.GetUserId();
        var result = await _messageService.MarkAllAsReadAsync(userId, otherUserId);
        return result.Success
            ? Ok(new { message = "All messages marked as read." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{messageId:int}")]
    public async Task<IActionResult> Edit(int messageId, [FromBody] EditMessageDto dto)
    {
        var userId = User.GetUserId();
        var result = await _messageService.EditMessageAsync(messageId, userId, dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{messageId:int}/like")]
    public async Task<IActionResult> Like(int messageId)
    {
        var userId = User.GetUserId();
        var result = await _messageService.LikeMessageAsync(messageId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{messageId:int}/like")]
    public async Task<IActionResult> Unlike(int messageId)
    {
        var userId = User.GetUserId();
        var result = await _messageService.UnlikeMessageAsync(messageId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

}
