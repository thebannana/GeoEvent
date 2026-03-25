using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;
using NotificationService.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace NotificationService.IntegrationTests.Helpers;

public static class NotificationSeeder
{
    public static async Task<Notification> SeedNotificationAsync(
        IServiceProvider services,
        int userId,
        NotificationType type = NotificationType.General,
        string title = "Test Notification",
        string description = "Test description",
        bool isRead = false)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

        var notification = new Notification
        {
            UserId = userId,
            Type = type,
            Title = title,
            Description = description,
            IsRead = isRead,
            CreatedAt = DateTime.UtcNow
        };

        db.Notifications.Add(notification);
        await db.SaveChangesAsync();
        return notification;
    }

    public static async Task<NotificationQueue> SeedQueueItemAsync(
        IServiceProvider services,
        int userId = 1,
        NotificationType type = NotificationType.General,
        NotificationQueueStatus status = NotificationQueueStatus.Pending,
        string payload = "{\"userId\":1,\"type\":\"General\",\"title\":\"T\",\"description\":\"D\"}",
        int attemptCount = 0,
        DateTime? scheduledAt = null)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

        var item = new NotificationQueue
        {
            UserId = userId,
            Type = type,
            Status = status,
            Payload = payload,
            AttemptCount = attemptCount,
            MaxAttempts = 3,
            ScheduledAt = scheduledAt ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            ErrorMessage = string.Empty
        };

        db.NotificationQueues.Add(item);
        await db.SaveChangesAsync();
        return item;
    }
}
