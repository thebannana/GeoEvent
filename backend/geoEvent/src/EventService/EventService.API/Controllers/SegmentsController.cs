using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

    [HttpGet("genres/{genreId:int}")]
    public async Task<IActionResult> GetGenreById(int genreId)
    {
        var result = await _eventService.GetGenreByIdAsync(genreId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("genres/{genreId:int}/subgenres")]
    public async Task<IActionResult> GetSubGenres(int genreId)
    {
        var result = await _eventService.GetSubGenresByGenreAsync(genreId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
