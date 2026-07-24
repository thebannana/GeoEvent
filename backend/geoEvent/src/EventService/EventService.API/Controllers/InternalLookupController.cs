using EventService.API.Filters;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/internal/lookup")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public class InternalLookupController : ControllerBase
{
    private readonly IEventService eventService;

    public InternalLookupController(IEventService eventService)
    {
        this.eventService = eventService;
    }

    [HttpGet("events/{eventId:int}")]
    public async Task<IActionResult> GetEvent(int eventId)
    {
        var result = await eventService.GetInternalEventLookupAsync(eventId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("comments/{commentId:int}")]
    public async Task<IActionResult> GetComment(int commentId)
    {
        var result = await eventService.GetInternalCommentLookupAsync(commentId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}