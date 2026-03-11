using LocationService.Application.DTOs;
using LocationService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

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
    public async Task<IActionResult> GetAll([FromQuery] CountryFilterDto filter)
    {
        var result = await _locationService.GetCountriesAsync(filter);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}")]
    public async Task<IActionResult> GetById(int countryId)
    {
        var result = await _locationService.GetCountryByIdAsync(countryId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("code/{code}")]
    public async Task<IActionResult> GetByCode(string code)
    {
        var result = await _locationService.GetCountryByCodeAsync(code);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}/cities")]
    public async Task<IActionResult> GetCities(int countryId)
    {
        var result = await _locationService.GetCitiesByCountryAsync(countryId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{countryId:int}/divisions")]
    public async Task<IActionResult> GetDivisions(
        int countryId, [FromQuery] DivisionFilterDto filter)
    {
        filter.CountryId = countryId;
        var result = await _locationService.GetDivisionsAsync(filter);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
