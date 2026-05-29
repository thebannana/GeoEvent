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
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto request)
    {
        var result = await _userService.UpdateProfileAsync(User.GetUserId(), request);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteMyAccount()
    {
        var result = await _userService.DeleteAccountAsync(User.GetUserId());
        return result.Success ? NoContent() : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        var result = await _userService.ChangePasswordAsync(User.GetUserId(), dto);
        return result.Success ? Ok(new { message = "Password changed successfully." }) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("me/activity-logs")]
    public async Task<IActionResult> GetMyActivityLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var result = await _userService.GetUserActivityLogsAsync(User.GetUserId(), page, pageSize);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("{userId:int}/public")]
    public async Task<IActionResult> GetPublicProfile(int userId)
    {
        var result = await _userService.GetPublicProfileAsync(userId);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("public")]
    public async Task<IActionResult> GetPublicProfiles([FromQuery] List<int> ids)
    {
        var result = await _userService.GetPublicProfilesAsync(ids);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{userId:int}/ban")]
    public async Task<IActionResult> BanUser(int userId)
    {
        var result = await _userService.BanUserAsync(userId);
        return result.Success ? Ok(new { message = "User banned." }) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{userId:int}/unban")]
    public async Task<IActionResult> UnbanUser(int userId)
    {
        var result = await _userService.UnbanUserAsync(userId);
        return result.Success ? Ok(new { message = "User unbanned." }) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{userId:int}/verify")]
    public async Task<IActionResult> VerifyUser(int userId)
    {
        var result = await _userService.AdminVerifyUserAsync(userId);
        return result.Success ? Ok(new { message = "User verified." }) : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<IActionResult> GetAllUsers([FromQuery] UserFilterDto filter)
    {
        var result = await _userService.GetAllUsersAsync(filter);
        return result.Success ? Ok(result.Data) : StatusCode(result.StatusCode, new { error = result.Error });
    }
}