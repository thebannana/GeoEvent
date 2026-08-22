using Microsoft.AspNetCore.Mvc;
using TicketService.API.Filters;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/internal/reservations")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public sealed class InternalReservationsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public InternalReservationsController(
        ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpPost("expire")]
    public async Task<IActionResult> Expire(
        CancellationToken cancellationToken)
    {
        var result =
            await _ticketService.ExpireReservationsAsync();

        return result.Success
            ? Ok(result.Data)
            : StatusCode(
                result.StatusCode,
                new { error = result.Error });
    }
}