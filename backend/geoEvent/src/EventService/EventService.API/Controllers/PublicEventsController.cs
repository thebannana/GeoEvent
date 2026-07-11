using Microsoft.AspNetCore.Mvc;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using EventService.API.Extensions;
using EventService.API.Filters;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/public/events")]
public class PublicEventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public PublicEventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] EventFilterDto filter)
    {
        int? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;
        var result = await _eventService.GetPublicAsync(filter, requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{eventId:int}")]
    public async Task<IActionResult> GetById(int eventId)
    {
        int? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;
        var result = await _eventService.GetPublicByIdAsync(eventId, requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] NearbyEventSearchDto dto)
    {
        var result = await _eventService.GetNearbyPublicAsync(dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}