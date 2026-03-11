using Microsoft.AspNetCore.Mvc;
using LocationService.Application.Interfaces.Services;

namespace LocationService.API.Controllers;

[ApiController]
[Route("api/postal-codes")]
public class PostalCodesController : ControllerBase
{
    private readonly ILocationService _locationService;

    public PostalCodesController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet("{postalCodeId:int}")]
    public async Task<IActionResult> GetById(int postalCodeId)
    {
        var result = await _locationService.GetPostalCodeByIdAsync(postalCodeId);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("code/{code}")]
    public async Task<IActionResult> GetByCode(string code)
    {
        var result = await _locationService.GetPostalCodeByCodeAsync(code);
        return result.Success ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
