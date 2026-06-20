using Microsoft.AspNetCore.Mvc;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Infrastructure.Filters;

namespace NotificationService.API.Controllers;

[ApiController]
[Route("api/internal/notifications")]
[ApiKeyAuth]
public class InternalNotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public InternalNotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNotificationDto dto)
    {
        var result = await _notificationService.CreateNotificationAsync(dto);

        return result.Success
            ? StatusCode(StatusCodes.Status201Created, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}