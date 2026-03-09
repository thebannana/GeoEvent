using Microsoft.AspNetCore.Mvc;
using LocationService.Application.Interfaces.Services;

namespace LocationService.API.Controllers;

[ApiController]
[Route("api/continents")]
public class ContinentsController : ControllerBase
{
    private readonly ILocationService _locationService;

    public ContinentsController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await _locationService.GetAllContinentsAsync();
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{continentId:int}")]
    public async Task<IActionResult> GetById(int continentId)
    {
        var result = await _locationService.GetContinentByIdAsync(continentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{continentId:int}/countries")]
    public async Task<IActionResult> GetCountries(int continentId)
    {
        var result = await _locationService.GetCountriesByContinentAsync(continentId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
