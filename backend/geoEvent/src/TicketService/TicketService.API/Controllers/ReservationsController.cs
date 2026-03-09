using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Extensions;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/reservations")]
[Authorize]
public class ReservationsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public ReservationsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateReservationDto dto,
        [FromQuery] decimal pricePerTicket = 0)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CreateReservationAsync(dto, userId, pricePerTicket);
        return result.Success
            ? CreatedAtAction(nameof(GetById), new { reservationId = result.Data!.ReservationId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{reservationId:int}/confirm")]
    public async Task<IActionResult> Confirm(int reservationId, [FromBody] ConfirmReservationDto dto)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.ConfirmReservationAsync(reservationId, dto, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{reservationId:int}/cancel")]
    public async Task<IActionResult> Cancel(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CancelReservationAsync(reservationId, userId);
        return result.Success
            ? Ok(new { message = "Reservation cancelled." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reservationId:int}")]
    public async Task<IActionResult> GetById(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetReservationAsync(reservationId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyReservations([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetUserReservationsAsync(userId, page, pageSize);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
