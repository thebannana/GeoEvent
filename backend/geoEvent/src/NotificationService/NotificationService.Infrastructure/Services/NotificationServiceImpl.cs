using System.Text.Json;
using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Entities;

namespace NotificationService.Infrastructure.Services;

public class NotificationServiceImpl : INotificationService
{
    private readonly INotificationRepository _repo;

    public NotificationServiceImpl(INotificationRepository repo)
    {
        _repo = repo;
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
        int userId, int page, int pageSize)
    {
        var result = await _repo.GetUserNotificationsAsync(userId, page, pageSize);
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

        await _repo.UpdateAsync(notification);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<NotificationQueueResponseDto>> QueueNotificationAsync(
        CreateNotificationDto dto, DateTime? scheduledAt = null)
    {
        var queueItem = new NotificationQueue
        {
            UserId = dto.UserId,
            Type = dto.Type,
            Payload = JsonSerializer.Serialize(dto),
            Status = "Pending",
            AttemptCount = 0,
            ScheduledAt = scheduledAt ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            ErrorMessage = string.Empty
        };

        var created = await _repo.CreateQueueItemAsync(queueItem);
        return ServiceResult<NotificationQueueResponseDto>.Ok(MapToQueueDto(created));
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

                var dto = JsonSerializer.Deserialize<CreateNotificationDto>(item.Payload);
                if (dto is not null)
                    await CreateNotificationAsync(dto);

                item.MarkAsSent();
                await _repo.UpdateQueueItemAsync(item);
            }
            catch (Exception ex)
            {
                item.MarkAsFailed(ex.Message);
                await _repo.UpdateQueueItemAsync(item);
            }
        }

        return ServiceResult<bool>.Ok(true);
    }

    // Mappers
    private static NotificationResponseDto MapToDto(Notification n) => new()
    {
        NotificationId = n.NotificationId,
        Type = n.Type,
        Title = n.Title,
        Description = n.Description,
        IsRead = n.IsRead,
        UserId = n.UserId,
        CreatedAt = n.CreatedAt
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
        Status = q.Status,
        Type = q.Type,
        Payload = q.Payload
    };
}
