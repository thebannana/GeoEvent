using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private const int MaxBulkProfileIds = 100;
    private const int MaxPageSize = 100;

    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("profiles")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProfiles([FromQuery] List<int>? ids)
    {
        if (ids is null || ids.Count == 0)
            return BadRequest(new { error = "At least one user ID must be provided." });

        var distinctIds = ids
            .Where(id => id > 0)
            .Distinct()
            .ToList();

        if (distinctIds.Count == 0)
            return BadRequest(new { error = "At least one valid user ID must be provided." });

        if (distinctIds.Count > MaxBulkProfileIds)
        {
            return BadRequest(new
            {
                error = $"A maximum of {MaxBulkProfileIds} user IDs can be requested at once."
            });
        }

        var profiles = await _userService.GetCommentUserProfilesAsync(distinctIds);
        return Ok(profiles);
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
        if (request is null)
            return BadRequest(new { error = "Request body is required." });

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
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var result = await _userService.ChangePasswordAsync(User.GetUserId(), dto);

        return result.Success
            ? Ok(new { message = "Password changed successfully." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{userId:int}/rating")]
    public async Task<IActionResult> RateUser(int userId, [FromBody] RateUserDto dto)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var raterId = User.GetUserId();
        var result = await _userService.RateUserAsync(userId, raterId, dto);

        return result.Success
            ? Ok(new { message = "Rating saved." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{userId:int}/rating")]
    public async Task<IActionResult> DeleteMyReview(int userId)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        var raterId = User.GetUserId();
        var result = await _userService.DeleteUserReviewAsync(userId, raterId);

        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("{userId:int}/public")]
    public async Task<IActionResult> GetPublicProfile(int userId)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        int? requesterId = null;

        if (User.Identity?.IsAuthenticated == true)
            requesterId = User.GetUserId();

        var result = await _userService.GetPublicProfileAsync(userId, requesterId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("{userId:int}/reviews")]
    public async Task<IActionResult> GetUserReviews(
        int userId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        if (page <= 0)
            return BadRequest(new { error = "Page must be greater than 0." });

        if (pageSize <= 0 || pageSize > MaxPageSize)
        {
            return BadRequest(new
            {
                error = $"PageSize must be between 1 and {MaxPageSize}."
            });
        }

        var result = await _userService.GetUserReviewsAsync(userId, page, pageSize);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("public")]
    public async Task<IActionResult> GetPublicProfiles([FromQuery] List<int>? ids)
    {
        if (ids is null || ids.Count == 0)
            return BadRequest(new { error = "At least one user ID must be provided." });

        var distinctIds = ids
            .Where(id => id > 0)
            .Distinct()
            .ToList();

        if (distinctIds.Count == 0)
            return BadRequest(new { error = "At least one valid user ID must be provided." });

        if (distinctIds.Count > MaxBulkProfileIds)
        {
            return BadRequest(new
            {
                error = $"A maximum of {MaxBulkProfileIds} user IDs can be requested at once."
            });
        }

        var result = await _userService.GetPublicProfilesAsync(distinctIds);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = AppRoles.Admin)]
    [HttpPost("{userId:int}/ban")]
    public async Task<IActionResult> BanUser(int userId)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        var result = await _userService.BanUserAsync(userId);

        return result.Success
            ? Ok(new { message = "User banned." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = AppRoles.Admin)]
    [HttpPost("{userId:int}/unban")]
    public async Task<IActionResult> UnbanUser(int userId)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        var result = await _userService.UnbanUserAsync(userId);

        return result.Success
            ? Ok(new { message = "User unbanned." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = AppRoles.Admin)]
    [HttpGet]
    public async Task<IActionResult> GetAllUsers([FromQuery] UserFilterDto filter)
    {
        if (filter.Page <= 0)
            return BadRequest(new { error = "Page must be greater than 0." });

        if (filter.PageSize <= 0 || filter.PageSize > MaxPageSize)
        {
            return BadRequest(new
            {
                error = $"PageSize must be between 1 and {MaxPageSize}."
            });
        }

        var result = await _userService.GetAllUsersAsync(filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}