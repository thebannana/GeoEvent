using EventService.API.Filters;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/internal/events")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public sealed class InternalEventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public InternalEventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("organizers/{userId:int}/count")]
    public async Task<IActionResult> GetOrganizerEventsCount(int userId)
    {
        var result = await _eventService.GetPublicCountByOrganizerAsync(userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}