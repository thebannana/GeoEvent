namespace MessageService.Domain.Entities;

public class Message
{
    public int Id { get; set; }
    public int SenderId { get; set; }
    public int RecipientId { get; set; }
    public int? EventId { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public bool IsDeletedBySender { get; set; }
    public bool IsDeletedByRecipient { get; set; }
    public int LikesCount { get; set; } = 0;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }
    public DateTime? EditedAt { get; set; }

    // Domain logic
    public bool IsVisibleTo(int userId) =>
        (SenderId == userId && !IsDeletedBySender) ||
        (RecipientId == userId && !IsDeletedByRecipient);

    public bool CanBeEditedBy(int userId) =>
        SenderId == userId && !IsDeletedBySender;

    public bool CanBeDeletedBy(int userId) =>
        SenderId == userId || RecipientId == userId;

    public void MarkAsRead()
    {
        IsRead = true;
        ReadAt = DateTime.UtcNow;
    }

    public void SoftDeleteFor(int userId)
    {
        if (SenderId == userId)
            IsDeletedBySender = true;
        if (RecipientId == userId)
            IsDeletedByRecipient = true;
    }

    public bool IsFullyDeleted() => IsDeletedBySender && IsDeletedByRecipient;

    public void Like() => LikesCount++;
    public void Unlike() => LikesCount = Math.Max(0, LikesCount - 1);
}
