using EventService.API.Security;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/admin/dashboard/events")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminDashboardEventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public AdminDashboardEventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var result = await _eventService.GetAdminEventStatsAsync();

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}