using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/bookmarks")]
[Authorize]
public class BookmarksController : ControllerBase
{
    private readonly IEventService _eventService;

    public BookmarksController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyBookmarks()
    {
        var result = await _eventService.GetUserBookmarksAsync(User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBookmarkDto dto)
    {
        var result = await _eventService.CreateBookmarkAsync(dto, User.GetUserId());
        return result.Success
            ? CreatedAtAction(nameof(GetMyBookmarks), result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{bookmarkId:int}")]
    public async Task<IActionResult> Delete(int bookmarkId)
    {
        var result = await _eventService.DeleteBookmarkAsync(bookmarkId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Bookmark removed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{bookmarkId:int}")]
    public async Task<IActionResult> Update(int bookmarkId, [FromBody] UpdateBookmarkDto dto)
    {
        var result = await _eventService.UpdateBookmarkAsync(bookmarkId, dto, User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}