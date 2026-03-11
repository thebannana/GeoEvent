using Microsoft.AspNetCore.Mvc;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces.Services;

namespace LocationService.API.Controllers;

[ApiController]
[Route("api/divisions")]
public class DivisionsController : ControllerBase
{
    private readonly ILocationService _locationService;

    public DivisionsController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] DivisionFilterDto filter)
    {
        var result = await _locationService.GetDivisionsAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{divisionId:int}")]
    public async Task<IActionResult> GetById(int divisionId)
    {
        var result = await _locationService.GetDivisionByIdAsync(divisionId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{divisionId:int}/children")]
    public async Task<IActionResult> GetChildren(int divisionId)
    {
        var filter = new DivisionFilterDto { ParentDivisionId = divisionId };
        var result = await _locationService.GetDivisionsAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{divisionId:int}/cities")]
    public async Task<IActionResult> GetCities(int divisionId)
    {
        var result = await _locationService.GetCitiesByDivisionAsync(divisionId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
