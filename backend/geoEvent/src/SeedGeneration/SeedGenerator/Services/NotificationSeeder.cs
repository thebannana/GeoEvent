using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;
using NotificationService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class NotificationSeeder : ISeeder
{
    private readonly NotificationDbContext _dbContext;
    private readonly IReadOnlyList<SeedNotificationOptions> _notifications;
    private readonly ILogger<NotificationSeeder> _logger;

    public NotificationSeeder(
        NotificationDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<NotificationSeeder> logger)
    {
        _dbContext = dbContext;
        _notifications = options.Value.SeedNotifications ?? new List<SeedNotificationOptions>();
        _logger = logger;
    }

    public string Name => "notifications";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_notifications.Count == 0)
        {
            _logger.LogWarning("No notifications configured in SeedNotifications.");
            return;
        }

        foreach (var seed in _notifications)
        {
            if (!Enum.TryParse<NotificationType>(seed.Type, true, out var type))
            {
                _logger.LogWarning("Skipping notification: Invalid Type {Type}.", seed.Type);
                continue;
            }

            if (seed.UserId <= 0)
            {
                _logger.LogWarning("Skipping notification: UserId must be > 0.");
                continue;
            }

            if (string.IsNullOrWhiteSpace(seed.Title) || string.IsNullOrWhiteSpace(seed.Description))
            {
                _logger.LogWarning("Skipping notification: Title and Description are required.");
                continue;
            }

            var notification = new Notification(
                type,
                seed.Title.Trim(),
                seed.Description.Trim(),
                seed.UserId,
                string.IsNullOrWhiteSpace(seed.ImageUrl) ? null : seed.ImageUrl.Trim());

            if (seed.IsRead)
            {
                notification.MarkAsRead();
            }

            await _dbContext.Notifications.AddAsync(notification, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Notification created: NotificationId {NotificationId}, Type {Type}, UserId {UserId}",
                notification.NotificationId, notification.Type, notification.UserId);
        }
    }
}