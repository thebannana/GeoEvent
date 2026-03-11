using Microsoft.AspNetCore.Mvc;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces.Services;

namespace LocationService.API.Controllers;

[ApiController]
[Route("api/cities")]
public class CitiesController : ControllerBase
{
    private readonly ILocationService _locationService;

    public CitiesController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] CityFilterDto filter)
    {
        var result = await _locationService.GetCitiesAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{cityId:int}")]
    public async Task<IActionResult> GetById(int cityId)
    {
        var result = await _locationService.GetCityByIdAsync(cityId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery] string term,
        [FromQuery] int limit = 10)
    {
        if (string.IsNullOrWhiteSpace(term))
            return BadRequest(new { error = "Search term is required." });

        limit = Math.Clamp(limit, 1, 50);    // guard against abuse

        var result = await _locationService.SearchCitiesAsync(term, limit);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] NearbySearchDto dto)
    {
        var result = await _locationService.GetNearbyCitiesAsync(dto);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{cityId:int}/postal-codes")]
    public async Task<IActionResult> GetPostalCodes(int cityId)
    {
        var result = await _locationService.GetPostalCodesByCityAsync(cityId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
