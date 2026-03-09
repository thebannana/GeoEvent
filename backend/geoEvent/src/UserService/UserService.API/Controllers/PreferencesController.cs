using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/preferences")]
[Authorize]
public class PreferencesController : ControllerBase
{
    private readonly IUserService _userService;

    public PreferencesController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyPreferences()
    {
        var userId = User.GetUserId();
        var result = await _userService.GetUserPreferencesAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut]
    public async Task<IActionResult> Upsert([FromBody] UpdatePreferenceDto dto)
    {
        var userId = User.GetUserId();
        var result = await _userService.UpsertPreferenceAsync(userId, dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{prefId:int}")]
    public async Task<IActionResult> Delete(int prefId)
    {
        var userId = User.GetUserId();
        var result = await _userService.DeletePreferenceAsync(userId, prefId);
        return result.Success
            ? Ok(new { message = "Preference removed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
