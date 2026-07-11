using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Extensions;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/reservations/{reservationId:int}/payments")]
[Authorize]
public class ReservationPaymentsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public ReservationPaymentsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpPost("paypal-order")]
    public async Task<IActionResult> CreatePayPalOrder(int reservationId)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CreateReservationPayPalOrderAsync(reservationId, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("paypal-capture")]
    public async Task<IActionResult> CapturePayPalOrder(
        int reservationId,
        [FromBody] CapturePayPalOrderDto dto)
    {
        var userId = User.GetUserId();
        var result = await _ticketService.CaptureReservationPayPalOrderAsync(reservationId, dto, userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}