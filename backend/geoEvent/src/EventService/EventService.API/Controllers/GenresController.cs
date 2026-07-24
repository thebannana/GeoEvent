using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Security;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/genres")]
public class GenresController : ControllerBase
{
    private readonly IEventService _eventService;

    public GenresController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20,
    [FromQuery] string? searchTerm = null)
    {
        var result = await _eventService.GetGenresPagedAsync(page, pageSize, searchTerm);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{genreId:int}")]
    public async Task<IActionResult> GetById(int genreId)
    {
        var result = await _eventService.GetGenreByIdAsync(genreId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{genreId:int}/subgenres")]
    public async Task<IActionResult> GetSubGenres(int genreId)
    {
        var result = await _eventService.GetSubGenresByGenreAsync(genreId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Create([FromBody] CreateGenreDto dto)
    {
        var result = await _eventService.CreateGenreAsync(dto);
        return result.Success
            ? CreatedAtAction(nameof(GetById), new { genreId = result.Data!.GenreId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{genreId:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Update(int genreId, [FromBody] UpdateGenreDto dto)
    {
        var result = await _eventService.UpdateGenreAsync(genreId, dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}