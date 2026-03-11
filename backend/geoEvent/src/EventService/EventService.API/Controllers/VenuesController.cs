using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/venues")]
public class VenuesController : ControllerBase
{
    private readonly IEventService _eventService;

    public VenuesController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("{venueId:int}")]
    public async Task<IActionResult> GetById(int venueId)
    {
        var result = await _eventService.GetVenueByIdAsync(venueId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("city/{cityId:int}")]
    public async Task<IActionResult> GetByCity(int cityId)
    {
        var result = await _eventService.GetVenuesByCityAsync(cityId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Create([FromBody] CreateVenueDto dto)
    {
        var result = await _eventService.CreateVenueAsync(dto);
        return result.Success
            ? CreatedAtAction(nameof(GetById),
                new { venueId = result.Data!.VenueId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{venueId:int}/price-zones")]
    public async Task<IActionResult> GetPriceZones(int venueId)
    {
        var result = await _eventService.GetPriceZonesByVenueAsync(venueId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{venueId:int}/price-zones")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> CreatePriceZone(
        int venueId, [FromBody] CreatePriceZoneDto dto)
    {
        if (dto.VenueId != venueId)
            return BadRequest(new { error = "VenueId mismatch." });

        var result = await _eventService.CreatePriceZoneAsync(dto, User.GetUserId());
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
