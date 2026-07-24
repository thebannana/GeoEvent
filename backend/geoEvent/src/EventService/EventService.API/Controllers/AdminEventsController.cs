using EventService.API.Security;
using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/admin/events")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminEventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public AdminEventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        var result = await _eventService.GetAllAsync(filter);
        return ToDataResult(result);
    }

    [HttpGet("{eventId:int}")]
    public async Task<IActionResult> GetById(int eventId)
    {
        var result = await _eventService.GetAdminByIdAsync(eventId);
        return ToDataResult(result);
    }

    [HttpPut("{eventId:int}")]
    public async Task<IActionResult> Update(int eventId, [FromBody] UpdateEventDto dto)
    {
        var result = await _eventService.AdminUpdateAsync(eventId, dto);
        return ToDataResult(result);
    }

    [HttpDelete("{eventId:int}")]
    public async Task<IActionResult> Delete(int eventId)
    {
        var result = await _eventService.AdminDeleteAsync(eventId);
        return ToMessageResult(result, "Event deleted.");
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