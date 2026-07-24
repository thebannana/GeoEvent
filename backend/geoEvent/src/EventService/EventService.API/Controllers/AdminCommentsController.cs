using EventService.API.Security;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/admin/comments")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminCommentsController : ControllerBase
{
    private readonly IEventService _eventService;

    public AdminCommentsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpPut("{commentId:int}")]
    public async Task<IActionResult> Update(int commentId, [FromBody] UpdateCommentDto dto)
    {
        var result = await _eventService.AdminUpdateCommentAsync(commentId, dto);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{commentId:int}")]
    public async Task<IActionResult> Delete(int commentId)
    {
        var result = await _eventService.AdminDeleteCommentAsync(commentId);

        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}