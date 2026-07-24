using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.Application.Common;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/admin/dashboard/users")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminDashboardUsersController : ControllerBase
{
    private readonly IUserService _userService;

    public AdminDashboardUsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var result = await _userService.GetAdminUsersDashboardStatsAsync();

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}