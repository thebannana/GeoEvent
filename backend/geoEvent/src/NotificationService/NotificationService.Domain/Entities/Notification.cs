namespace NotificationService.Domain.Entities;

public class Notification
{
    public int NotificationId { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public int? UserId { get; set; }
    public DateTime CreatedAt { get; set; }

    // Domain logic
    public void MarkAsRead() => IsRead = true;
}
