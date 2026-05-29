using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Extensions;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/events")]
[Authorize]
public class EventInteractionsController : ControllerBase
{
    private readonly IEventService _eventService;

    public EventInteractionsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpPost("{eventId:int}/like")]
    public async Task<IActionResult> Like(int eventId)
    {
        var result = await _eventService.LikeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event liked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}/like")]
    public async Task<IActionResult> Unlike(int eventId)
    {
        var result = await _eventService.UnlikeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event unliked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}