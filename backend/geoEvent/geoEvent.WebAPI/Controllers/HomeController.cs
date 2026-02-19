using Microsoft.AspNetCore.Mvc;
using geoEvent.Services.Interfaces;
using geoEvent.Model.Models;
using System.Reflection.Metadata.Ecma335;
using geoEvent.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace geoEvent.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly IEventRepository _repo;

    public EventsController(IEventRepository repo) => _repo = repo;

    [HttpGet("{id}")]
    public async Task<ActionResult<Event>> Get(int id)
    {
        var evt = await _repo.GetByIdAsync(id);

        return evt;
    }

    [HttpPost]
    public async Task<ActionResult> Create(Event evt)
    {
        await _repo.AddAsync(evt);
        return CreatedAtAction(nameof(Get), new { id = evt.Id }, evt);
    }
}
