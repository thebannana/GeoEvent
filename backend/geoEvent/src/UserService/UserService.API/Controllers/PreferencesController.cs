using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
    public async Task<IActionResult> GetMine()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Invalid user token." });

        var result = await _userService.GetUserPreferencesAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("users/{userId:int}")]
    public async Task<IActionResult> GetByUserId(int userId)
    {
        var result = await _userService.GetUserPreferencesAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}