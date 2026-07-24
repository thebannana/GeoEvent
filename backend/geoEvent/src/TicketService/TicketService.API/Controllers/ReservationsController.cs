using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using TicketService.API.Extensions;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;
using TicketService.Domain.Enums;

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

    [HttpGet("refund-requests")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetRefundRequests([FromQuery] AdminRefundRequestsQueryDto query)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.GetAdminRefundRequestsAsync(query, userId, role);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [AllowAnonymous]
    [HttpGet("public/events/{eventId:int}/attendees")]
    public async Task<IActionResult> GetPublicEventAttendees(
        int eventId,
        [FromQuery] PublicEventAttendeesFilterDto filter)
    {
        var result = await _ticketService.GetPublicEventAttendeesAsync(eventId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{reservationId:int}/cash-confirm")]
    public async Task<IActionResult> ConfirmCash(int reservationId)
    {
        var userId = User.GetUserId();

        var reservationResult = await _ticketService.GetReservationAsync(reservationId, userId);
        if (!reservationResult.Success || reservationResult.Data is null)
            return StatusCode(reservationResult.StatusCode, new { error = reservationResult.Error });

        if (!string.Equals(
                reservationResult.Data.Status,
                ReservationStatus.Pending.ToString(),
                StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { error = "Reservation is not pending." });
        }

        var dto = new ConfirmReservationDto
        {
            PaymentMethod = PaymentMethod.Cash,
            Currency = reservationResult.Data.Currency
        };

        var result = await _ticketService.ConfirmReservationAsync(reservationId, dto, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("events/{eventId:int}/attendees/manage")]
    public async Task<IActionResult> GetManageableEventAttendees(
    int eventId,
    [FromQuery] ManageableEventAttendeesFilterDto filter)
    {
        var result = await _ticketService.GetManageableEventAttendeesAsync(eventId, filter);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reservationId:int}/tickets")]
    public async Task<IActionResult> GetTickets(
        int reservationId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetTicketsByReservationAsync(reservationId, userId, page, pageSize);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{reservationId:int}/payments")]
    public async Task<IActionResult> GetPayments(
        int reservationId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.GetReservationPaymentsAsync(reservationId, userId, page, pageSize);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("events/{eventId:int}/reservations/{reservationId:int}/collect-cash")]
    public async Task<IActionResult> CollectCash(int eventId, int reservationId)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.MarkCashCollectedAsync(
            eventId,
            reservationId,
            userId,
            role);

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

    [HttpGet("events/{eventId:int}/reservations")]
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

    [HttpPost("{reservationId:int}/refund-request")]
    public async Task<IActionResult> RequestRefund(
        int reservationId,
        [FromBody] RequestRefundDto dto)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.RequestRefundAsync(reservationId, dto, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("events/{eventId:int}/reservations/{reservationId:int}/approve-refund")]
    public async Task<IActionResult> ApproveRefund(
        int eventId,
        int reservationId,
        [FromBody] ApproveRefundDto dto)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.ApproveRefundAsync(
            eventId,
            reservationId,
            dto,
            userId,
            role);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("events/{eventId:int}/reservations/{reservationId:int}/reject-refund")]
    public async Task<IActionResult> RejectRefund(
        int eventId,
        int reservationId,
        [FromBody] RejectRefundDto dto)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.RejectRefundAsync(
            eventId,
            reservationId,
            dto,
            userId,
            role);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("events/{eventId:int}/reservations/{reservationId:int}/remove")]
    public async Task<IActionResult> RemoveAttendeeReservation(int eventId, int reservationId)
    {
        var userId = User.GetUserId();
        var role = User.GetRole();

        var result = await _ticketService.RemoveAttendeeReservationAsync(
            eventId,
            reservationId,
            userId,
            role);

        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("events/{eventId:int}/summary")]
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