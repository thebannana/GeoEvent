using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Extensions;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/tickets")]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public TicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpGet("{ticketId:int}")]
    [Authorize]
    public async Task<IActionResult> GetById(int ticketId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetTicketAsync(ticketId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("my")]
    [Authorize]
    public async Task<IActionResult> GetMyTickets()
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetUserTicketsAsync(userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("validate")]
    [AllowAnonymous]
    public async Task<IActionResult> Validate([FromQuery] string qrCode)
    {
        if (string.IsNullOrWhiteSpace(qrCode))
            return BadRequest(new { error = "QR code is required." });

        var result = await _ticketService.ValidateTicketAsync(qrCode);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{ticketId:int}/cancel")]
    [Authorize]
    public async Task<IActionResult> Cancel(int ticketId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CancelTicketAsync(ticketId, userId);
        return result.Success
            ? Ok(new { message = "Ticket cancelled." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
