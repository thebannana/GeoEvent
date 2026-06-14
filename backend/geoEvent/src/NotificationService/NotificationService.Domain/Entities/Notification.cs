using NotificationService.Domain.Enums;

namespace NotificationService.Domain.Entities;

public class Notification
{
    public int NotificationId { get; set; }
    public NotificationType Type { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public bool IsRead { get; set; } = false;
    public int? UserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }

    public void MarkAsRead()
    {
        IsRead = true;
        ReadAt = DateTime.UtcNow;
    }
}