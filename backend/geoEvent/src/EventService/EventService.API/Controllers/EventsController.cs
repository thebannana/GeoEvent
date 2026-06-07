using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EventService.API.Extensions;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/events")]
[Authorize(Roles = "User,Organizer,Admin")]
public class EventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public EventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet("mine/drafts")]
    public async Task<IActionResult> GetMyDrafts([FromQuery] EventFilterDto filter)
    {
        filter ??= new EventFilterDto();
        filter.OrganizerId = User.GetUserId();

        var result = await _eventService.GetMyDraftsAsync(filter, User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
    [HttpGet("mine")]
    public async Task<IActionResult> GetMine([FromQuery] EventFilterDto filter)
    {
        filter ??= new EventFilterDto();
        filter.OrganizerId = User.GetUserId();

        var result = await _eventService.GetAllAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEventDto dto)
    {
        var result = await _eventService.CreateAsync(dto, User.GetUserId());
        return result.Success
            ? CreatedAtAction(
                nameof(PublicEventsController.GetById),
                "PublicEvents",
                new { eventId = result.Data!.EventId },
                result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPut("{eventId:int}")]
    public async Task<IActionResult> Update(int eventId, [FromBody] UpdateEventDto dto)
    {
        var result = await _eventService.UpdateAsync(eventId, dto, User.GetUserId());
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}")]
    public async Task<IActionResult> Delete(int eventId)
    {
        var result = await _eventService.DeleteAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/publish")]
    public async Task<IActionResult> Publish(int eventId)
    {
        var result = await _eventService.PublishAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event published." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("liked")]
    [Authorize]
    public async Task<IActionResult> GetLikedEvents()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdValue, out var userId))
            return Unauthorized(new { error = "Invalid user token." });

        var result = await _eventService.GetLikedEventsAsync(userId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/like")]
    [Authorize]
    public async Task<IActionResult> LikeEvent(int eventId)
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdValue, out var userId))
            return Unauthorized(new { error = "Invalid user token." });

        var result = await _eventService.LikeAsync(eventId, userId);

        return result.Success
            ? Ok(new { message = "Event liked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}/like")]
    [Authorize]
    public async Task<IActionResult> UnlikeEvent(int eventId)
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdValue, out var userId))
            return Unauthorized(new { error = "Invalid user token." });

        var result = await _eventService.UnlikeAsync(eventId, userId);

        return result.Success
            ? Ok(new { message = "Event unliked." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/cancel")]
    public async Task<IActionResult> Cancel(int eventId)
    {
        var result = await _eventService.CancelAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event cancelled." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/postpone")]
    public async Task<IActionResult> Postpone(int eventId)
    {
        var result = await _eventService.PostponeAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event postponed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/complete")]
    public async Task<IActionResult> Complete(int eventId)
    {
        var result = await _eventService.CompleteAsync(eventId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Event completed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{eventId:int}/images")]
    public async Task<IActionResult> AddImage(int eventId, [FromBody] AddImageDto dto)
    {
        var result = await _eventService.AddImageAsync(
            eventId,
            dto.ImageUrl,
            dto.IsCover,
            User.GetUserId());

        return result.Success
            ? Ok(new { message = "Image added." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{eventId:int}/images/{imageId:int}")]
    public async Task<IActionResult> DeleteImage(int eventId, int imageId)
    {
        var result = await _eventService.DeleteImageAsync(imageId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Image deleted." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{eventId:int}/images/{imageId:int}/cover")]
    public async Task<IActionResult> SetCover(int eventId, int imageId)
    {
        var result = await _eventService.SetCoverImageAsync(eventId, imageId, User.GetUserId());
        return result.Success
            ? Ok(new { message = "Cover image set." })
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