using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using System.ComponentModel.DataAnnotations;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/events")]
public class EventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public EventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] EventFilterDto filter)
    {
        var result = await _eventService.GetAllAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{eventId:int}")]
    public async Task<IActionResult> GetById(int eventId)
    {
        var result = await _eventService.GetByIdAsync(eventId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Create([FromBody] CreateEventDto dto)
    {
        var result = await _eventService.CreateAsync(dto, User.GetUserId());
        return result.Success
            ? CreatedAtAction(nameof(GetById),
                new { eventId = result.Data!.EventId }, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{eventId:int}")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Update(int eventId, [FromBody] UpdateEventDto dto)
    {
        var result = await _eventService.UpdateAsync(eventId, dto, User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Delete(int eventId)
    {
        var result = await _eventService.DeleteAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/publish")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Publish(int eventId)
    {
        var result = await _eventService.PublishAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event published." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/cancel")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Cancel(int eventId)
    {
        var result = await _eventService.CancelAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event cancelled." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/like")]
    [Authorize]
    public async Task<IActionResult> Like(int eventId)
    {
        var result = await _eventService.LikeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event liked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}/like")]
    [Authorize]
    public async Task<IActionResult> Unlike(int eventId)
    {
        var result = await _eventService.UnlikeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event unliked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/images")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> AddImage(int eventId, [FromBody] AddImageDto dto)
    {
        var result = await _eventService.AddImageAsync(
            eventId, dto.ImageUrl, dto.IsCover, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Image added." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}/images/{imageId:int}")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> DeleteImage(int eventId, int imageId)
    {
        var result = await _eventService.DeleteImageAsync(imageId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Image deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{eventId:int}/images/{imageId:int}/cover")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> SetCover(int eventId, int imageId)
    {
        var result = await _eventService.SetCoverImageAsync(eventId, imageId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Cover image set." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/postpone")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Postpone(int eventId)
    {
        var result = await _eventService.PostponeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event postponed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/complete")]
    [Authorize(Roles = "Organizer,Admin")]
    public async Task<IActionResult> Complete(int eventId)
    {
        var result = await _eventService.CompleteAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event completed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] NearbyEventSearchDto dto)
    {
        var result = await _eventService.GetNearbyAsync(dto);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

}

public class AddImageDto
{
    [Required]
    [Url]
    [StringLength(500)]
    public string ImageUrl { get; set; } = string.Empty;
    public bool IsCover { get; set; } = false;
}
