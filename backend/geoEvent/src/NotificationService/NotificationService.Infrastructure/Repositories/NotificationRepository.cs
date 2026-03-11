using Microsoft.EntityFrameworkCore;
using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;
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
    int userId, NotificationFilterDto filter)
    {
        var query = _context.Notifications
            .Where(n => n.UserId == userId);

        if (filter.IsRead.HasValue)
            query = query.Where(n => n.IsRead == filter.IsRead.Value);

        query = query.OrderByDescending(n => n.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Notification>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
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
            .ExecuteUpdateAsync(s => s
                .SetProperty(n => n.IsRead, true)
                .SetProperty(n => n.ReadAt, DateTime.UtcNow));
    }

    // Queue
    public async Task<NotificationQueue?> GetQueueItemByIdAsync(int queueId) =>
        await _context.NotificationQueues
            .FirstOrDefaultAsync(q => q.QueueId == queueId);

    public async Task<List<NotificationQueue>> GetPendingQueueItemsAsync(int batchSize) =>
     await _context.NotificationQueues
         .Where(q =>
             q.Status == NotificationQueueStatus.Pending &&
             q.ScheduledAt <= DateTime.UtcNow)
         .OrderBy(q => q.ScheduledAt)
         .Take(batchSize)
         .ToListAsync();


    public async Task<List<NotificationQueue>> GetFailedRetryableItemsAsync() =>
    await _context.NotificationQueues
        .Where(q =>
            q.Status == NotificationQueueStatus.Failed &&
            q.AttemptCount < q.MaxAttempts)
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

    public async Task DeleteAsync(Notification notification)
    {
        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();
    }

    public async Task<PagedResult<NotificationQueue>> GetQueueItemsAsync(QueueFilterDto filter)
    {
        var query = _context.NotificationQueues.AsQueryable();

        if (filter.Status.HasValue)
            query = query.Where(q => q.Status == filter.Status.Value);

        if (filter.Type.HasValue)
            query = query.Where(q => q.Type == filter.Type.Value);

        query = query.OrderByDescending(q => q.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<NotificationQueue>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<int> GetQueueDepthAsync(NotificationQueueStatus status) =>
    await _context.NotificationQueues
        .CountAsync(q => q.Status == status);

}
