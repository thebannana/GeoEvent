using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Security;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/segments")]
public class SegmentsController : ControllerBase
{
    private readonly IEventService _eventService;

    public SegmentsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await _eventService.GetAllSegmentsAsync();
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{segmentId:int}")]
    public async Task<IActionResult> GetById(int segmentId)
    {
        var result = await _eventService.GetSegmentByIdAsync(segmentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{segmentId:int}/genres")]
    public async Task<IActionResult> GetGenres(int segmentId)
    {
        var result = await _eventService.GetGenresBySegmentAsync(segmentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Create([FromBody] CreateSegmentDto dto)
    {
        var result = await _eventService.CreateSegmentAsync(dto);
        return result.Success
            ? CreatedAtAction(nameof(GetById), new { segmentId = result.Data!.SegmentId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{segmentId:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Update(int segmentId, [FromBody] UpdateSegmentDto dto)
    {
        var result = await _eventService.UpdateSegmentAsync(segmentId, dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}