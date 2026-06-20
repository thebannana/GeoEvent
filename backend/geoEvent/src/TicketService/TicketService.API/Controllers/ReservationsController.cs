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
    private readonly IPayPalService _payPalService;

    public ReservationsController(ITicketService ticketService, IPayPalService payPalService)
    {
        _ticketService = ticketService;
        _payPalService = payPalService;
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

    [HttpPost("{reservationId:int}/paypal-order")]
    public async Task<IActionResult> CreatePayPalOrder(int reservationId)
    {
        var userId = User.GetUserId();
        var res = await _ticketService.GetReservationAsync(reservationId, userId);
        if (!res.Success || res.Data == null)
            return StatusCode(res.StatusCode, new { error = res.Error });

        if (res.Data.Status != TicketService.Domain.Enums.ReservationStatus.Pending.ToString())
            return BadRequest(new { error = "Reservation is not pending." });

        var orderResult = await _payPalService.CreateOrderAsync(res.Data.TotalAmount, res.Data.Currency, reservationId.ToString());
        return orderResult.Success
            ? Ok(orderResult.Data)
            : StatusCode(orderResult.StatusCode, new { error = orderResult.Error });
    }

    [HttpPost("{reservationId:int}/paypal-capture")]
    public async Task<IActionResult> CapturePayPalOrder(int reservationId, [FromBody] CapturePayPalOrderDto dto)
    {
        var userId = User.GetUserId();
        var captureResult = await _payPalService.CaptureOrderAsync(dto.OrderId);
        
        if (!captureResult.Success || captureResult.Data == null)
            return StatusCode(captureResult.StatusCode, new { error = captureResult.Error });

        if (captureResult.Data.Status != "COMPLETED")
            return BadRequest(new { error = "PayPal order not completed." });

        var confirmDto = new ConfirmReservationDto
        {
            PaymentReference = captureResult.Data.Id,
            ProviderPaymentId = captureResult.Data.Id,
            ProviderOrderId = dto.OrderId,
            PaymentMethod = TicketService.Domain.Enums.PaymentMethod.PayPal,
            Currency = "EUR" // Usually need to get from reservation or default, but let's assume EUR or from res
        };

        var res = await _ticketService.GetReservationAsync(reservationId, userId);
        if (res.Success && res.Data != null)
        {
            confirmDto.Currency = res.Data.Currency;
        }

        var result = await _ticketService.ConfirmReservationAsync(reservationId, confirmDto, userId);

        return result.Success
            ? Ok(result.Data)
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
    [Authorize]
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

    [HttpPatch("events/{eventId:int}/reservations/{reservationId:int}/remove")]
    [Authorize]
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
    [Authorize]
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

public class CapturePayPalOrderDto
{
    public string OrderId { get; set; } = string.Empty;
}