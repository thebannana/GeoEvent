using EventService.API.Extensions;
using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

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

    [HttpGet("mine")]
    public async Task<IActionResult> GetMine([FromQuery] EventFilterDto filter)
    {
        filter ??= new EventFilterDto();
        filter.OrganizerId = User.GetUserId();

        var result = await _eventService.GetAllAsync(filter);
        return ToDataResult(result);
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
        return ToDataResult(result);
    }

    [HttpDelete("{eventId:int}")]
    public async Task<IActionResult> Delete(int eventId)
    {
        var result = await _eventService.DeleteAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event deleted.");
    }

    [HttpPost("{eventId:int}/publish")]
    public async Task<IActionResult> Publish(int eventId)
    {
        var result = await _eventService.PublishAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event published.");
    }

    [HttpGet("liked")]
    public async Task<IActionResult> GetLikedEvents([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _eventService.GetLikedEventsAsync(User.GetUserId(), page, pageSize);
        return ToDataResult(result);
    }

    [HttpPost("{eventId:int}/like")]
    public async Task<IActionResult> LikeEvent(int eventId)
    {
        var result = await _eventService.LikeAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event liked.");
    }

    [HttpDelete("{eventId:int}/like")]
    public async Task<IActionResult> UnlikeEvent(int eventId)
    {
        var result = await _eventService.UnlikeAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event unliked.");
    }

    [HttpPost("{eventId:int}/cancel")]
    public async Task<IActionResult> Cancel(int eventId)
    {
        var result = await _eventService.CancelAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event cancelled.");
    }

    [HttpPost("{eventId:int}/complete")]
    public async Task<IActionResult> Complete(int eventId)
    {
        var result = await _eventService.CompleteAsync(eventId, User.GetUserId());
        return ToMessageResult(result, "Event completed.");
    }

    [HttpPost("{eventId:int}/images")]
    public async Task<IActionResult> AddImage(int eventId, [FromBody] AddImageDto dto)
    {
        var result = await _eventService.AddImageAsync(
            eventId,
            dto.ImageUrl,
            dto.IsCover,
            User.GetUserId());

        return ToMessageResult(result, "Image added.");
    }

    [HttpDelete("{eventId:int}/images/{imageId:int}")]
    public async Task<IActionResult> DeleteImage(int eventId, int imageId)
    {
        var result = await _eventService.DeleteImageAsync(imageId, User.GetUserId());
        return ToMessageResult(result, "Image deleted.");
    }

    [HttpPatch("{eventId:int}/images/{imageId:int}/cover")]
    public async Task<IActionResult> SetCover(int eventId, int imageId)
    {
        var result = await _eventService.SetCoverImageAsync(eventId, imageId, User.GetUserId());
        return ToMessageResult(result, "Cover image set.");
    }

    private IActionResult ToDataResult<T>(ServiceResult<T> result)
    {
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    private IActionResult ToMessageResult(ServiceResult<bool> result, string successMessage)
    {
        return result.Success
            ? Ok(new { message = successMessage })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}

public class AddImageDto
{
    [Required(ErrorMessage = "Image URL is required.")]
    [Url(ErrorMessage = "Image URL must be a valid absolute URL.")]
    [StringLength(500, ErrorMessage = "Image URL cannot be longer than 500 characters.")]
    public string ImageUrl { get; set; } = string.Empty;

    public bool IsCover { get; set; }
}