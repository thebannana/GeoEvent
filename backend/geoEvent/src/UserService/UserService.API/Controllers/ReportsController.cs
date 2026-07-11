using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.API.Extensions;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Enums;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/reports")]
[Authorize]
public class ReportsController : ControllerBase
{
    private const int MaxPageSize = 100;

    private readonly IUserService _userService;

    public ReportsController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateReportDto dto)
    {
        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var userId = User.GetUserId();
        var result = await _userService.CreateReportAsync(dto, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyReports(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page <= 0)
            return BadRequest(new { error = "Page must be greater than 0." });

        if (pageSize <= 0 || pageSize > MaxPageSize)
        {
            return BadRequest(new
            {
                error = $"PageSize must be between 1 and {MaxPageSize}."
            });
        }

        var userId = User.GetUserId();
        var result = await _userService.GetUserReportsAsync(userId, page, pageSize);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (page <= 0)
            return BadRequest(new { error = "Page must be greater than 0." });

        if (pageSize <= 0 || pageSize > MaxPageSize)
        {
            return BadRequest(new
            {
                error = $"PageSize must be between 1 and {MaxPageSize}."
            });
        }

        ReportStatus? parsedStatus = null;

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<ReportStatus>(status, true, out var parsed))
                return BadRequest(new { error = "Invalid report status." });

            parsedStatus = parsed;
        }

        var result = await _userService.GetAllReportsAsync(parsedStatus, page, pageSize);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{reportId:int}/resolve")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Resolve(int reportId, [FromBody] ResolveReportDto dto)
    {
        if (reportId <= 0)
            return BadRequest(new { error = "A valid report ID must be provided." });

        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var userId = User.GetUserId();
        var result = await _userService.ResolveReportAsync(reportId, dto, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reportId:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> GetById(int reportId)
    {
        if (reportId <= 0)
            return BadRequest(new { error = "A valid report ID must be provided." });

        var result = await _userService.GetReportByIdAsync(reportId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}