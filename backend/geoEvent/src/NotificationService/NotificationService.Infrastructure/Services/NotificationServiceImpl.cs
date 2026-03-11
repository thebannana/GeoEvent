using System.Text.Json;
using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;

namespace NotificationService.Infrastructure.Services;

public class NotificationServiceImpl : INotificationService
{
    private readonly INotificationRepository _repo;
    private readonly INotificationProcessor _processor;

    public NotificationServiceImpl(
        INotificationRepository repo,
        INotificationProcessor processor)
    {
        _repo = repo;
        _processor = processor;
    }

    public async Task<ServiceResult<bool>> ProcessQueueAsync(int batchSize = 10)
    {
        var items = await _repo.GetPendingQueueItemsAsync(batchSize);

        foreach (var item in items)
        {
            try
            {
                item.MarkAsProcessing();
                await _repo.UpdateQueueItemAsync(item);

                await _processor.ProcessAsync(item);

                item.MarkAsSent();
            }
            catch (Exception ex)
            {
                item.MarkAsFailed(ex.Message[..Math.Min(ex.Message.Length, 500)]);
            }
            finally
            {
                await _repo.UpdateQueueItemAsync(item);
            }
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> RetryFailedAsync()
    {
        var items = await _repo.GetFailedRetryableItemsAsync();

        foreach (var item in items)
        {
            item.ResetForRetry();
            await _repo.UpdateQueueItemAsync(item);
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> CancelQueueItemAsync(int queueId)
    {
        var item = await _repo.GetQueueItemByIdAsync(queueId);
        if (item is null)
            return ServiceResult<bool>.NotFound($"Queue item {queueId} not found.");

        if (item.Status != NotificationQueueStatus.Pending &&
            item.Status != NotificationQueueStatus.Failed)
            return ServiceResult<bool>.Fail(
                "Only Pending or Failed queue items can be cancelled.");

        item.Cancel();
        await _repo.UpdateQueueItemAsync(item);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<NotificationQueueResponseDto>> GetQueueItemAsync(int queueId)
    {
        var item = await _repo.GetQueueItemByIdAsync(queueId);
        if (item is null)
            return ServiceResult<NotificationQueueResponseDto>.NotFound(
                $"Queue item {queueId} not found.");

        return ServiceResult<NotificationQueueResponseDto>.Ok(MapToQueueDto(item));
    }

    public async Task<ServiceResult<PagedResult<NotificationQueueResponseDto>>> GetQueueItemsAsync(
        QueueFilterDto filter)
    {
        var result = await _repo.GetQueueItemsAsync(filter);
        var mapped = new PagedResult<NotificationQueueResponseDto>
        {
            Items = result.Items.Select(MapToQueueDto),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };
        return ServiceResult<PagedResult<NotificationQueueResponseDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<NotificationResponseDto>> GetNotificationAsync(
        int notificationId, int userId)
    {
        var notification = await _repo.GetByIdAsync(notificationId);
        if (notification is null)
            return ServiceResult<NotificationResponseDto>.NotFound("Notification not found.");
        if (notification.UserId != userId)
            return ServiceResult<NotificationResponseDto>.Forbidden("Access denied.");

        return ServiceResult<NotificationResponseDto>.Ok(MapToDto(notification));
    }

    public async Task<ServiceResult<PagedResult<NotificationResponseDto>>> GetUserNotificationsAsync(
    int userId, NotificationFilterDto filter)
    {
        var result = await _repo.GetUserNotificationsAsync(userId, filter);
        var mapped = new PagedResult<NotificationResponseDto>
        {
            Items = result.Items.Select(MapToDto),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };
        return ServiceResult<PagedResult<NotificationResponseDto>>.Ok(mapped);
    }


    public async Task<ServiceResult<int>> GetUnreadCountAsync(int userId)
    {
        var count = await _repo.GetUnreadCountAsync(userId);
        return ServiceResult<int>.Ok(count);
    }

    public async Task<ServiceResult<NotificationResponseDto>> CreateNotificationAsync(
        CreateNotificationDto dto)
    {
        var notification = new Notification
        {
            UserId = dto.UserId,
            Type = dto.Type,
            Title = dto.Title,
            Description = dto.Description,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _repo.CreateAsync(notification);
        return ServiceResult<NotificationResponseDto>.Ok(MapToDto(created));
    }

    public async Task<ServiceResult<bool>> MarkAsReadAsync(int notificationId, int userId)
    {
        var notification = await _repo.GetByIdAsync(notificationId);
        if (notification is null)
            return ServiceResult<bool>.NotFound("Notification not found.");
        if (notification.UserId != userId)
            return ServiceResult<bool>.Forbidden("Access denied.");

        notification.MarkAsRead();
        await _repo.UpdateAsync(notification);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId)
    {
        await _repo.MarkAllAsReadAsync(userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteNotificationAsync(
    int notificationId, int userId)
    {
        var notification = await _repo.GetByIdAsync(notificationId);
        if (notification is null)
            return ServiceResult<bool>.NotFound("Notification not found.");
        if (notification.UserId != userId)
            return ServiceResult<bool>.Forbidden("Access denied.");

        await _repo.DeleteAsync(notification);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<NotificationQueueResponseDto>> QueueNotificationAsync(
    QueueNotificationDto dto)
    {
        var queueItem = new NotificationQueue
        {
            UserId = dto.UserId,
            Type = dto.Type,
            Payload = dto.Payload,
            Status = NotificationQueueStatus.Pending,
            AttemptCount = 0,
            ScheduledAt = dto.ScheduledAt ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            ErrorMessage = string.Empty
        };

        var created = await _repo.CreateQueueItemAsync(queueItem);
        return ServiceResult<NotificationQueueResponseDto>.Created(MapToQueueDto(created));
    }

    // Mappers
    private static NotificationResponseDto MapToDto(Notification n) => new()
    {
        NotificationId = n.NotificationId,
        Type = n.Type.ToString(),
        Title = n.Title,
        Description = n.Description,
        IsRead = n.IsRead,
        UserId = n.UserId,
        CreatedAt = n.CreatedAt,
        ReadAt = n.ReadAt
    };


    private static NotificationQueueResponseDto MapToQueueDto(NotificationQueue q) => new()
    {
        QueueId = q.QueueId,
        ScheduledAt = q.ScheduledAt,
        ProcessedAt = q.ProcessedAt,
        CreatedAt = q.CreatedAt,
        UserId = q.UserId,
        ErrorMessage = q.ErrorMessage,
        AttemptCount = q.AttemptCount,
        MaxAttempts = q.MaxAttempts,
        CanRetry = q.CanRetry(),
        Status = q.Status.ToString(),
        Type = q.Type.ToString(),
        Payload = q.Payload
    };

}
