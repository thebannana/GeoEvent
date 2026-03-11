using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.Application.Interfaces.Services;

namespace TicketService.API.Controllers;

[ApiController]
[Route("api/events/{eventId:int}/tickets")]
public class EventTicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public EventTicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll(int eventId)
    {
        var result = await _ticketService.GetEventTicketsAsync(eventId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{eventTicketId:int}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(int eventTicketId)
    {
        var result = await _ticketService.GetEventTicketAsync(eventTicketId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
