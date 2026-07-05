using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using TicketService.API.Extensions;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;
using TicketService.Domain.Enums;
using TicketService.Infrastructure.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/reservations")]
[Authorize]
public class ReservationsController : ControllerBase
{
    private readonly ITicketService _ticketService;
    private readonly IPayPalService _payPalService;
    private readonly IConfiguration _configuration;

    public ReservationsController(
        ITicketService ticketService,
        IPayPalService payPalService,
        IConfiguration configuration)
    {
        _ticketService = ticketService;
        _payPalService = payPalService;
        _configuration = configuration;
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
    [Authorize]
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

    [HttpPost("{reservationId:int}/paypal-order")]
    public async Task<IActionResult> CreatePayPalOrder(int reservationId)
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

        if (reservationResult.Data.TotalAmount <= 0)
        {
            return BadRequest(new { error = "Free reservations do not require PayPal checkout." });
        }

        var returnUrlBase = _configuration["PayPal:ReturnUrl"]?.Trim();
        var cancelUrlBase = _configuration["PayPal:CancelUrl"]?.Trim();
        var mode = _configuration["PayPal:Mode"];
        var clientId = _configuration["PayPal:ClientId"];
        var clientSecret = _configuration["PayPal:ClientSecret"];

        if (string.IsNullOrWhiteSpace(returnUrlBase) || string.IsNullOrWhiteSpace(cancelUrlBase))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                error = "PayPal return/cancel URLs are not configured."
            });
        }

        var returnUrl = BuildPayPalRedirectUrl(returnUrlBase, reservationId);
        var cancelUrl = BuildPayPalRedirectUrl(cancelUrlBase, reservationId);

        var paypalCurrency = PayPalService.NormalizeCurrencyForPayPal(reservationResult.Data.Currency);
        var paypalAmount = PayPalService.NormalizeAmountForPayPal(
            reservationResult.Data.TotalAmount,
            reservationResult.Data.Currency);

        var orderResult = await _payPalService.CreateOrderAsync(
            reservationResult.Data.TotalAmount,
            reservationResult.Data.Currency,
            reservationId.ToString(),
            returnUrl,
            cancelUrl);

        if (!orderResult.Success || orderResult.Data is null)
        {
            return StatusCode(orderResult.StatusCode <= 0 ? 500 : orderResult.StatusCode, new
            {
                error = orderResult.Error ?? "Failed to create PayPal order.",
                debug = new
                {
                    reservationId,
                    originalAmount = reservationResult.Data.TotalAmount,
                    originalCurrency = reservationResult.Data.Currency,
                    paypalAmount,
                    paypalCurrency,
                    returnUrl,
                    cancelUrl,
                    mode,
                    hasClientId = !string.IsNullOrWhiteSpace(clientId),
                    hasClientSecret = !string.IsNullOrWhiteSpace(clientSecret)
                }
            });
        }

        var attachResult = await _ticketService.AttachPendingPayPalOrderAsync(
            reservationId,
            userId,
            orderResult.Data.OrderId);

        if (!attachResult.Success)
        {
            return StatusCode(attachResult.StatusCode, new { error = attachResult.Error });
        }

        return Ok(orderResult.Data);
    }

    [HttpPost("{reservationId:int}/paypal-capture")]
    public async Task<IActionResult> CapturePayPalOrder(
        int reservationId,
        [FromBody] CapturePayPalOrderDto dto)
    {
        var userId = User.GetUserId();

        if (dto is null || string.IsNullOrWhiteSpace(dto.OrderId))
            return BadRequest(new { error = "OrderId is required." });

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

        if (string.IsNullOrWhiteSpace(reservationResult.Data.PendingProviderOrderId))
        {
            return BadRequest(new { error = "No pending PayPal order is attached to this reservation." });
        }

        if (!string.Equals(
                reservationResult.Data.PendingProviderOrderId,
                dto.OrderId,
                StringComparison.Ordinal))
        {
            return BadRequest(new { error = "OrderId does not match the pending PayPal order for this reservation." });
        }

        var orderDetails = await _payPalService.GetOrderAsync(dto.OrderId);
        if (!orderDetails.Success || orderDetails.Data is null)
            return StatusCode(orderDetails.StatusCode, new { error = orderDetails.Error });

        if (!string.Equals(orderDetails.Data.OrderId, dto.OrderId, StringComparison.Ordinal))
            return BadRequest(new { error = "PayPal order ID mismatch." });

        if (!string.Equals(orderDetails.Data.ReferenceId, reservationId.ToString(), StringComparison.Ordinal))
            return BadRequest(new { error = "PayPal order does not belong to this reservation." });

        if (!PayPalService.AmountMatchesForPayPal(
                reservationResult.Data.TotalAmount,
                reservationResult.Data.Currency,
                orderDetails.Data.Amount,
                orderDetails.Data.Currency))
        {
            return BadRequest(new
            {
                error = "PayPal amount or currency does not match reservation amount.",
                debug = new
                {
                    reservationAmount = reservationResult.Data.TotalAmount,
                    reservationCurrency = reservationResult.Data.Currency,
                    expectedPayPalAmount = PayPalService.NormalizeAmountForPayPal(
                        reservationResult.Data.TotalAmount,
                        reservationResult.Data.Currency),
                    expectedPayPalCurrency = PayPalService.NormalizeCurrencyForPayPal(
                        reservationResult.Data.Currency),
                    actualPayPalAmount = orderDetails.Data.Amount,
                    actualPayPalCurrency = orderDetails.Data.Currency
                }
            });
        }

        if (!string.Equals(orderDetails.Data.Status, "APPROVED", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(orderDetails.Data.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { error = "PayPal order is not approved." });
        }

        var captureResult = await _payPalService.CaptureOrderAsync(dto.OrderId);
        if (!captureResult.Success || captureResult.Data is null)
            return StatusCode(captureResult.StatusCode, new { error = captureResult.Error });

        if (!string.Equals(captureResult.Data.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { error = "PayPal order not completed." });

        var confirmDto = new ConfirmReservationDto
        {
            PaymentReference = captureResult.Data.Id,
            ProviderPaymentId = captureResult.Data.Id,
            ProviderOrderId = dto.OrderId,
            PaymentMethod = PaymentMethod.PayPal,
            Currency = reservationResult.Data.Currency
        };

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
    [Authorize]
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
    [Authorize]
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

    private static string BuildPayPalRedirectUrl(string baseUrl, int reservationId)
    {
        var trimmed = baseUrl.Trim();
        var separator = trimmed.Contains('?', StringComparison.Ordinal) ? "&" : "?";
        return $"{trimmed}{separator}reservationId={reservationId}";
    }
}