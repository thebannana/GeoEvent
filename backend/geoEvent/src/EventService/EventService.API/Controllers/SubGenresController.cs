using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/subgenres")]
public class SubGenresController : ControllerBase
{
    private readonly IEventService _eventService;

    public SubGenresController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("{subGenreId:int}")]
    public async Task<IActionResult> GetById(int subGenreId)
    {
        var result = await _eventService.GetSubGenreByIdAsync(subGenreId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateSubGenreDto dto)
    {
        var result = await _eventService.CreateSubGenreAsync(dto);
        return result.Success
            ? CreatedAtAction(nameof(GetById), new { subGenreId = result.Data!.SubGenreId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{subGenreId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int subGenreId, [FromBody] UpdateSubGenreDto dto)
    {
        var result = await _eventService.UpdateSubGenreAsync(subGenreId, dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}