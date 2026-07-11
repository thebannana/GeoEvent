using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TicketService.API.Filters;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/internal/event-tickets")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public sealed class InternalEventTicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public InternalEventTicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpPost("default")]
    public async Task<IActionResult> CreateDefault([FromBody] CreateDefaultEventTicketRequest request)
    {
        var result = await _ticketService.CreateDefaultEventTicketAsync(request);

        if (result.Success)
        {
            return result.StatusCode == StatusCodes.Status201Created
                ? StatusCode(StatusCodes.Status201Created, result.Data)
                : Ok(result.Data);
        }

        return StatusCode(result.StatusCode, new { error = result.Error });
    }
}