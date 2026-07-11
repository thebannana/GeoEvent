using NotificationService.Domain.Enums;
using NotificationService.Domain.Exceptions;

namespace NotificationService.Domain.Entities;

public class Notification
{
    public int NotificationId { get; private set; }
    public NotificationType Type { get; private set; }
    public string Title { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public string? ImageUrl { get; private set; }
    public bool IsRead { get; private set; }
    public int UserId { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ReadAt { get; private set; }

    private Notification() { }

    public Notification(
        NotificationType type,
        string title,
        string description,
        int userId,
        string? imageUrl = null)
    {
        if (userId <= 0)
            throw new InvalidOperationException("User ID must be greater than zero.");

        Type = type;
        Title = Normalize(title, 200, "Title");
        Description = Normalize(description, 2000, "Description");
        UserId = userId;
        ImageUrl = string.IsNullOrWhiteSpace(imageUrl) ? null : imageUrl.Trim();
        CreatedAt = DateTime.UtcNow;
        IsRead = false;
    }

    public void MarkAsRead()
    {
        if (IsRead)
            throw new NotificationAlreadyReadException(NotificationId);

        IsRead = true;
        ReadAt = DateTime.UtcNow;
    }

    private static string Normalize(string value, int maxLength, string fieldName)
    {
        var trimmed = (value ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(trimmed))
            throw new InvalidOperationException($"{fieldName} cannot be empty.");

        if (trimmed.Length > maxLength)
            throw new InvalidOperationException($"{fieldName} cannot exceed {maxLength} characters.");

        return trimmed;
    }
}