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
    private readonly INotificationService notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        this.notificationService = notificationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyNotifications([FromQuery] NotificationFilterDto filter)
    {
        var userId = User.GetUserId();
        var result = await notificationService.GetUserNotificationsAsync(userId, filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = User.GetUserId();
        var result = await notificationService.GetUnreadCountAsync(userId);
        return result.Success
            ? Ok(new { unreadCount = result.Data })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{notificationId:int}")]
    public async Task<IActionResult> GetById(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await notificationService.GetNotificationAsync(notificationId, userId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("{notificationId:int}/read")]
    public async Task<IActionResult> MarkAsRead(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await notificationService.MarkAsReadAsync(notificationId, userId);
        return result.Success
            ? Ok(new { message = "Notification marked as read." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPatch("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = User.GetUserId();
        var result = await notificationService.MarkAllAsReadAsync(userId);
        return result.Success
            ? Ok(new { message = "All notifications marked as read." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete("{notificationId:int}")]
    public async Task<IActionResult> Delete(int notificationId)
    {
        var userId = User.GetUserId();
        var result = await notificationService.DeleteNotificationAsync(notificationId, userId);
        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteAll()
    {
        var userId = User.GetUserId();
        var result = await notificationService.DeleteAllNotificationsAsync(userId);
        return result.Success
            ? NoContent()
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}