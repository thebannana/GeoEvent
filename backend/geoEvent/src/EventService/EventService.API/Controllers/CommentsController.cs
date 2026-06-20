using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/comments")]
public class CommentsController : ControllerBase
{
    private readonly IEventService _eventService;

    public CommentsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("event/{eventId:int}")]
    public async Task<IActionResult> GetByEvent(int eventId)
    {
        var result = await _eventService.GetEventCommentsAsync(eventId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{commentId:int}/replies")]
    public async Task<IActionResult> GetReplies(int commentId)
    {
        var result = await _eventService.GetRepliesAsync(commentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{commentId:int}")]
    public async Task<IActionResult> GetById(int commentId)
    {
        var result = await _eventService.GetCommentByIdAsync(commentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateCommentDto dto)
    {
        var result = await _eventService.CreateCommentAsync(dto, User.GetUserId());

        return result.Success
            ? CreatedAtAction(nameof(GetById), new { commentId = result.Data!.CommentId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{commentId:int}")]
    [Authorize]
    public async Task<IActionResult> Update(int commentId, [FromBody] UpdateCommentDto dto)
    {
        var result = await _eventService.UpdateCommentAsync(commentId, dto, User.GetUserId());

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{commentId:int}")]
    [Authorize]
    public async Task<IActionResult> Delete(int commentId)
    {
        var result = await _eventService.DeleteCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? Ok(new { message = "Comment deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{commentId:int}/like")]
    [Authorize]
    public async Task<IActionResult> Like(int commentId)
    {
        var result = await _eventService.LikeCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? Ok(new { message = "Comment liked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{commentId:int}/like")]
    [Authorize]
    public async Task<IActionResult> Unlike(int commentId)
    {
        var result = await _eventService.UnlikeCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? Ok(new { message = "Comment unliked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}