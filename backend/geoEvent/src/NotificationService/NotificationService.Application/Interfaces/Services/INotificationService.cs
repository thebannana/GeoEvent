using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Domain.Enums;

namespace NotificationService.Application.Interfaces.Services;

public interface INotificationService
{
    // ── Notifications ─────────────────────────────────────────
    Task<ServiceResult<NotificationResponseDto>> GetNotificationAsync(int notificationId, int userId);
    Task<ServiceResult<PagedResult<NotificationResponseDto>>> GetUserNotificationsAsync(int userId, NotificationFilterDto filter);
    Task<ServiceResult<int>> GetUnreadCountAsync(int userId);
    Task<ServiceResult<NotificationResponseDto>> CreateNotificationAsync(CreateNotificationDto dto);
    Task<ServiceResult<bool>> MarkAsReadAsync(int notificationId, int userId);
    Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId);
    Task<ServiceResult<bool>> DeleteNotificationAsync(int notificationId, int userId);

    // ── Queue ─────────────────────────────────────────────────
    Task<ServiceResult<NotificationQueueResponseDto>> QueueNotificationAsync(QueueNotificationDto dto);
    Task<ServiceResult<bool>> ProcessQueueAsync(int batchSize = 10);
    Task<ServiceResult<bool>> RetryFailedAsync();
    Task<ServiceResult<bool>> CancelQueueItemAsync(int queueId);
    Task<ServiceResult<PagedResult<NotificationQueueResponseDto>>> GetQueueItemsAsync(QueueFilterDto filter);
    Task<ServiceResult<NotificationQueueResponseDto>> GetQueueItemAsync(int queueId);
}
