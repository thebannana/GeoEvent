using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Extensions;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/tickets")]
[Authorize]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public TicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpGet("{ticketId:int}")]
    public async Task<IActionResult> GetById(int ticketId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetTicketAsync(ticketId, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyTickets([FromQuery] TicketFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetUserTicketsAsync(userId, filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("validate")]
    [Authorize(Roles = "Admin,User")]
    public async Task<IActionResult> Validate([FromBody] ValidateTicketScanDto dto)
    {
        if (dto == null || string.IsNullOrWhiteSpace(dto.QrCode))
            return BadRequest(new { error = "QR code is required." });

        var validatorUserId = User.GetUserId();
        var validatorRole = User.GetRole();

        var result = await _ticketService.ValidateTicketScanAsync(
            dto,
            validatorUserId,
            validatorRole);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{ticketId:int}/cancel")]
    public async Task<IActionResult> Cancel(int ticketId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CancelTicketAsync(ticketId, userId);

        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}