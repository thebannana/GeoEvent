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
    public async Task<IActionResult> GetMine([FromQuery] PreferencesFilterDto filter)
    {
        var result = await _userService.GetUserPreferencesAsync(
            User.GetUserId(),
            filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("users/{userId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetByUserId(
        int userId,
        [FromQuery] PreferencesFilterDto filter)
    {
        var result = await _userService.GetUserPreferencesAsync(userId, filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}