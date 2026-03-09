using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        var result = await _userService.GetProfileAsync(User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto request)
    {
        var result = await _userService.UpdateProfileAsync(User.GetUserId(), request);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteMyAccount()
    {
        var result = await _userService.DeleteAccountAsync(User.GetUserId());
        return result.Success
            ? Ok(new { message = "Account deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    // ── Admin only ─────────────────────────────────────────────

    [HttpPost("{userId}/ban")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> BanUser(int userId)
    {
        var result = await _userService.BanUserAsync(userId);
        return result.Success
            ? Ok(new { message = "User banned." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{userId}/unban")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UnbanUser(int userId)
    {
        var result = await _userService.UnbanUserAsync(userId);
        return result.Success
            ? Ok(new { message = "User unbanned." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{userId}/verify")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> VerifyUser(int userId)
    {
        var result = await _userService.VerifyEmailAsync(userId);
        return result.Success
            ? Ok(new { message = "User verified." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
