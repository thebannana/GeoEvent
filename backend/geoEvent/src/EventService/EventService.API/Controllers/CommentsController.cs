using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/comments")]
[Authorize]
public class CommentsController : ControllerBase
{
    private readonly IEventService _eventService;

    public CommentsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("{commentId:int}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(int commentId)
    {
        int? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;

        var result = await _eventService.GetCommentByIdAsync(commentId, requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{commentId:int}/like")]
    public async Task<IActionResult> Like(int commentId)
    {
        var result = await _eventService.LikeCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{commentId:int}/like")]
    public async Task<IActionResult> Unlike(int commentId)
    {
        var result = await _eventService.UnlikeCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("event/{eventId:int}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetByEvent(
        int eventId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        int? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;

        var result = await _eventService.GetEventCommentsAsync(
            eventId,
            page,
            pageSize,
            requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{commentId:int}/replies")]
    [AllowAnonymous]
    public async Task<IActionResult> GetReplies(
        int commentId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        int? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;

        var result = await _eventService.GetRepliesAsync(
            commentId,
            page,
            pageSize,
            requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCommentDto dto)
    {
        var result = await _eventService.CreateCommentAsync(dto, User.GetUserId());

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{commentId:int}")]
    public async Task<IActionResult> Update(int commentId, [FromBody] UpdateCommentDto dto)
    {
        var result = await _eventService.UpdateCommentAsync(commentId, dto, User.GetUserId());

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{commentId:int}")]
    public async Task<IActionResult> Delete(int commentId)
    {
        var result = await _eventService.DeleteCommentAsync(commentId, User.GetUserId());

        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}