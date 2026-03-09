using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/reports")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly IUserService _userService;

    public ReportsController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateReportDto dto)
    {
        var userId = User.GetUserId();
        var result = await _userService.CreateReportAsync(dto, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyReports()
    {
        var userId = User.GetUserId();
        var result = await _userService.GetUserReportsAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _userService.GetAllReportsAsync(status, page, pageSize);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{reportId:int}/resolve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Resolve(int reportId, [FromBody] ResolveReportDto dto)
    {
        var userId = User.GetUserId();
        var result = await _userService.ResolveReportAsync(reportId, dto, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
