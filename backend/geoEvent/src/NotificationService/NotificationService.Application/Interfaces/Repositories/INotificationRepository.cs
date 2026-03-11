using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;

namespace NotificationService.Application.Interfaces.Repositories;

public interface INotificationRepository
{
    // ── Notifications ─────────────────────────────────────────
    Task<Notification?> GetByIdAsync(int notificationId);
    Task<PagedResult<Notification>> GetUserNotificationsAsync(int userId, NotificationFilterDto filter);
    Task<int> GetUnreadCountAsync(int userId);
    Task<Notification> CreateAsync(Notification notification);
    Task UpdateAsync(Notification notification);
    Task DeleteAsync(Notification notification);
    Task MarkAllAsReadAsync(int userId);

    // ── Queue ─────────────────────────────────────────────────
    Task<NotificationQueue?> GetQueueItemByIdAsync(int queueId);
    Task<List<NotificationQueue>> GetPendingQueueItemsAsync(int batchSize);
    Task<List<NotificationQueue>> GetFailedRetryableItemsAsync();
    Task<PagedResult<NotificationQueue>> GetQueueItemsAsync(QueueFilterDto filter);
    Task<NotificationQueue> CreateQueueItemAsync(NotificationQueue queueItem);
    Task UpdateQueueItemAsync(NotificationQueue queueItem);
    Task<int> GetQueueDepthAsync(NotificationQueueStatus status);
}
