using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Domain.Entities;

namespace NotificationService.Application.Interfaces.Repositories;

public interface INotificationRepository
{
    Task<Notification?> GetByIdAsync(int notificationId);
    Task<PagedResult<Notification>> GetUserNotificationsAsync(int userId, NotificationFilterDto filter);
    Task<int> GetUnreadCountAsync(int userId);
    Task<Notification> CreateAsync(Notification notification);
    Task UpdateAsync(Notification notification);
    Task DeleteAsync(Notification notification);
    Task MarkAllAsReadAsync(int userId);
}