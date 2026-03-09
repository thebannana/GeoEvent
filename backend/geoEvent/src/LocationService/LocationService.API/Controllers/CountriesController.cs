using Microsoft.AspNetCore.Mvc;
using LocationService.Application.Interfaces.Services;

namespace LocationService.API.Controllers;

[ApiController]
[Route("api/countries")]
public class CountriesController : ControllerBase
{
    private readonly ILocationService _locationService;

    public CountriesController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await _locationService.GetAllCountriesAsync();
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}")]
    public async Task<IActionResult> GetById(int countryId)
    {
        var result = await _locationService.GetCountryByIdAsync(countryId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}/divisions")]
    public async Task<IActionResult> GetDivisions(int countryId)
    {
        var result = await _locationService.GetDivisionsByCountryAsync(countryId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}/cities")]
    public async Task<IActionResult> GetCities(int countryId)
    {
        var result = await _locationService.GetCitiesByCountryAsync(countryId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("divisions/{divisionId:int}")]
    public async Task<IActionResult> GetDivisionById(int divisionId)
    {
        var result = await _locationService.GetDivisionByIdAsync(divisionId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("divisions/{divisionId:int}/children")]
    public async Task<IActionResult> GetChildDivisions(int divisionId)
    {
        var result = await _locationService.GetChildDivisionsAsync(divisionId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
