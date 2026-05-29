using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/public/events")]
[AllowAnonymous]
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
        filter ??= new EventFilterDto();

        var result = await _eventService.GetPublicAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{eventId:int}", Name = nameof(GetById))]
    public async Task<IActionResult> GetById(int eventId)
    {
        var requesterId = User.Identity?.IsAuthenticated == true
            ? User.GetUserId()
            : (int?)null;

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