using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/preferences")]
[Authorize]
public class PreferencesController : ControllerBase
{
    private const int MaxPageSize = 100;

    private readonly IUserService _userService;

    public PreferencesController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMine([FromQuery] PreferencesFilterDto filter)
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

        var result = await _userService.GetUserPreferencesAsync(User.GetUserId(), filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("users/{userId:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> GetByUserId(
        int userId,
        [FromQuery] PreferencesFilterDto filter)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        if (filter.Page <= 0)
            return BadRequest(new { error = "Page must be greater than 0." });

        if (filter.PageSize <= 0 || filter.PageSize > MaxPageSize)
        {
            return BadRequest(new
            {
                error = $"PageSize must be between 1 and {MaxPageSize}."
            });
        }

        var result = await _userService.GetUserPreferencesAsync(userId, filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}