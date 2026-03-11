using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NotificationService.API.Extensions;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;

namespace NotificationService.API.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyNotifications([FromQuery] NotificationFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await _notificationService.GetUserNotificationsAsync(userId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }


    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = User.GetUserId();
        var result = await _notificationService.GetUnreadCountAsync(userId);
        return result.Success
            ? Ok(new { unreadCount = result.Data })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{notificationId:int}")]
    public async Task<IActionResult> GetById(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await _notificationService.GetNotificationAsync(notificationId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{notificationId:int}/read")]
    public async Task<IActionResult> MarkAsRead(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await _notificationService.MarkAsReadAsync(notificationId, userId);
        return result.Success
            ? Ok(new { message = "Notification marked as read." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = User.GetUserId();
        var result = await _notificationService.MarkAllAsReadAsync(userId);
        return result.Success
            ? Ok(new { message = "All notifications marked as read." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{notificationId:int}")]
    public async Task<IActionResult> Delete(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await _notificationService.DeleteNotificationAsync(notificationId, userId);
        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
