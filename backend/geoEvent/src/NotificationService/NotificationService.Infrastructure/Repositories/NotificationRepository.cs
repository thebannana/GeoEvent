using Microsoft.EntityFrameworkCore;
using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Domain.Entities;
using NotificationService.Infrastructure.Persistence;

namespace NotificationService.Infrastructure.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly NotificationDbContext context;

    public NotificationRepository(NotificationDbContext context)
    {
        this.context = context;
    }

    public async Task<Notification?> GetByIdAsync(int notificationId)
    {
        return await context.Notifications
            .FirstOrDefaultAsync(n => n.NotificationId == notificationId);
    }

    public async Task<PagedResult<Notification>> GetUserNotificationsAsync(
        int userId,
        NotificationFilterDto filter)
    {
        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 100);

        var query = context.Notifications
            .Where(n => n.UserId == userId);

        if (filter.IsRead.HasValue)
        {
            query = query.Where(n => n.IsRead == filter.IsRead.Value);
        }

        query = query.OrderByDescending(n => n.CreatedAt);

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

    public async Task<int> GetUnreadCountAsync(int userId)
    {
        return await context.Notifications
            .CountAsync(n => n.UserId == userId && !n.IsRead);
    }

    public async Task<Notification> CreateAsync(Notification notification)
    {
        context.Notifications.Add(notification);
        await context.SaveChangesAsync();
        return notification;
    }

    public async Task UpdateAsync(Notification notification)
    {
        context.Notifications.Update(notification);
        await context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Notification notification)
    {
        context.Notifications.Remove(notification);
        await context.SaveChangesAsync();
    }

    public async Task MarkAllAsReadAsync(int userId)
    {
        await context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(s => s
                .SetProperty(n => n.IsRead, true)
                .SetProperty(n => n.ReadAt, DateTime.UtcNow));
    }

    public async Task DeleteAllAsync(int userId)
    {
        await context.Notifications
            .Where(n => n.UserId == userId)
            .ExecuteDeleteAsync();
    }
}