using NotificationService.Application.Common;
using NotificationService.Domain.Entities;

namespace NotificationService.Application.Interfaces.Repositories;

public interface INotificationRepository
{
    // Notifications
    Task<Notification?> GetByIdAsync(int notificationId);
    Task<PagedResult<Notification>> GetUserNotificationsAsync(int userId, int page, int pageSize);
    Task<int> GetUnreadCountAsync(int userId);
    Task<Notification> CreateAsync(Notification notification);
    Task UpdateAsync(Notification notification);
    Task MarkAllAsReadAsync(int userId);

    // Queue
    Task<NotificationQueue?> GetQueueItemByIdAsync(int queueId);
    Task<List<NotificationQueue>> GetPendingQueueItemsAsync(int batchSize);
    Task<List<NotificationQueue>> GetFailedQueueItemsAsync();
    Task<NotificationQueue> CreateQueueItemAsync(NotificationQueue queueItem);
    Task UpdateQueueItemAsync(NotificationQueue queueItem);
}
