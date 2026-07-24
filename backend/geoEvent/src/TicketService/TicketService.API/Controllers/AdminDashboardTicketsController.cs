using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Extensions;
using TicketService.Application.Common;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/admin/dashboard/tickets")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminDashboardTicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public AdminDashboardTicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.GetAdminDashboardTicketStatsAsync(userId, role);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}