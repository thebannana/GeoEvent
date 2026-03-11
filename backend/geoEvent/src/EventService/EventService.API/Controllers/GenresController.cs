using Microsoft.AspNetCore.Mvc;
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

    [HttpGet("{genreId:int}")]
    public async Task<IActionResult> GetById(int genreId)
    {
        var result = await _eventService.GetGenreByIdAsync(genreId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{genreId:int}/subgenres")]
    public async Task<IActionResult> GetSubGenres(int genreId)
    {
        var result = await _eventService.GetSubGenresByGenreAsync(genreId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
