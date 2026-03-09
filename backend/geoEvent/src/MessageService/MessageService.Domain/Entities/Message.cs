namespace MessageService.Domain.Entities;

public class Message
{
    public int Id { get; set; }
    public int SenderId { get; set; }
    public int RecipientId { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public bool IsDeletedBySender { get; set; }
    public bool IsDeletedByRecipient { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }
}
