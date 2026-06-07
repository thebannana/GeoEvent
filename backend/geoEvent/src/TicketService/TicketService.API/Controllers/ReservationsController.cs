using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
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

    [AllowAnonymous]
    [HttpGet("public/events/{eventId:int}/attendees")]
    public async Task<IActionResult> GetPublicEventAttendees(int eventId)
    {
        var result = await _ticketService.GetPublicEventAttendeesAsync(eventId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [EnableRateLimiting("create-reservation")]
    public async Task<IActionResult> Create([FromBody] CreateReservationDto dto)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CreateReservationAsync(dto, userId);

        return result.Success
            ? CreatedAtAction(
                nameof(GetById),
                new { reservationId = result.Data!.ReservationId },
                result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("checkout")]
    public async Task<IActionResult> CompleteCheckout([FromBody] CompleteCheckoutDto dto)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CompleteCheckoutAsync(dto, userId);

        return result.Success
            ? Ok(result.Data)
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

    [HttpPatch("{reservationId:int}/cancel")]
    public async Task<IActionResult> Cancel(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CancelReservationAsync(reservationId, userId);

        return result.Success
            ? NoContent()
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
    public async Task<IActionResult> GetMyReservations([FromQuery] ReservationFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetUserReservationsAsync(userId, filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reservationId:int}/tickets")]
    public async Task<IActionResult> GetTickets(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetTicketsByReservationAsync(reservationId, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reservationId:int}/payments")]
    public async Task<IActionResult> GetPayments(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetReservationPaymentsAsync(reservationId, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("events/{eventId:int}/reservations")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> GetEventReservations(
        int eventId,
        [FromQuery] ReservationFilterDto filter)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.GetEventReservationsAsync(
            eventId,
            userId,
            role,
            filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("events/{eventId:int}/summary")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> GetEventSummary(int eventId)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.GetEventReservationSummaryAsync(
            eventId,
            userId,
            role);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}