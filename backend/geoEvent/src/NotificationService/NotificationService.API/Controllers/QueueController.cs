using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NotificationService.API.Extensions;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;

namespace NotificationService.API.Controllers;

[ApiController]
[Route("api/queue")]
[Authorize(Roles = "Admin")]
public class QueueController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public QueueController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] QueueFilterDto filter)
    {
        var result = await _notificationService.GetQueueItemsAsync(filter);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpGet("{queueId:int}")]
    public async Task<IActionResult> GetById(int queueId)
    {
        var result = await _notificationService.GetQueueItemAsync(queueId);
        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost]
    public async Task<IActionResult> Queue([FromBody] QueueNotificationDto dto)
    {
        var result = await _notificationService.QueueNotificationAsync(dto);
        return result.Success
            ? StatusCode(StatusCodes.Status201Created, result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("process")]
    public async Task<IActionResult> Process([FromQuery] int batchSize = 10)
    {
        var result = await _notificationService.ProcessQueueAsync(batchSize);
        return result.Success
            ? Ok(new { message = "Queue processed." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("retry-failed")]
    public async Task<IActionResult> RetryFailed()
    {
        var result = await _notificationService.RetryFailedAsync();
        return result.Success
            ? Ok(new { message = "Failed items queued for retry." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("{queueId:int}/cancel")]
    public async Task<IActionResult> Cancel(int queueId)
    {
        var result = await _notificationService.CancelQueueItemAsync(queueId);
        return result.Success
            ? Ok(new { message = "Queue item cancelled." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}
