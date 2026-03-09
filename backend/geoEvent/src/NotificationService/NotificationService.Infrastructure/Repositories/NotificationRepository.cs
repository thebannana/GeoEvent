using Microsoft.EntityFrameworkCore;
using NotificationService.Application.Common;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Domain.Entities;
using NotificationService.Infrastructure.Persistence;

namespace NotificationService.Infrastructure.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly NotificationDbContext _context;

    public NotificationRepository(NotificationDbContext context)
    {
        _context = context;
    }

    // Notifications
    public async Task<Notification?> GetByIdAsync(int notificationId) =>
        await _context.Notifications
            .FirstOrDefaultAsync(n => n.NotificationId == notificationId);

    public async Task<PagedResult<Notification>> GetUserNotificationsAsync(
        int userId, int page, int pageSize)
    {
        var query = _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Notification>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<int> GetUnreadCountAsync(int userId) =>
        await _context.Notifications
            .CountAsync(n => n.UserId == userId && !n.IsRead);

    public async Task<Notification> CreateAsync(Notification notification)
    {
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
        return notification;
    }

    public async Task UpdateAsync(Notification notification)
    {
        _context.Notifications.Update(notification);
        await _context.SaveChangesAsync();
    }

    public async Task MarkAllAsReadAsync(int userId)
    {
        await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
    }

    // Queue
    public async Task<NotificationQueue?> GetQueueItemByIdAsync(int queueId) =>
        await _context.NotificationQueues
            .FirstOrDefaultAsync(q => q.QueueId == queueId);

    public async Task<List<NotificationQueue>> GetPendingQueueItemsAsync(int batchSize) =>
        await _context.NotificationQueues
            .Where(q => q.Status == "Pending" && q.ScheduledAt <= DateTime.UtcNow)
            .OrderBy(q => q.ScheduledAt)
            .Take(batchSize)
            .ToListAsync();

    public async Task<List<NotificationQueue>> GetFailedQueueItemsAsync() =>
        await _context.NotificationQueues
            .Where(q => q.Status == "Failed" && q.AttemptCount < 3)
            .OrderBy(q => q.CreatedAt)
            .ToListAsync();

    public async Task<NotificationQueue> CreateQueueItemAsync(NotificationQueue queueItem)
    {
        _context.NotificationQueues.Add(queueItem);
        await _context.SaveChangesAsync();
        return queueItem;
    }

    public async Task UpdateQueueItemAsync(NotificationQueue queueItem)
    {
        _context.NotificationQueues.Update(queueItem);
        await _context.SaveChangesAsync();
    }
}
