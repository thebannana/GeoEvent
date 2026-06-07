namespace MessageService.Domain.Entities;

public class ChatMessage
{
    public long Id { get; set; }
    public long ThreadId { get; set; }
    public int SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? EditedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    public long? ReplyToMessageId { get; set; }
    public int LikesCount { get; set; }

    public ChatThread Thread { get; set; } = default!;
    public ChatMessage? ReplyToMessage { get; set; }
    public ICollection<ChatMessage> Replies { get; set; } = new List<ChatMessage>();
    public ICollection<ChatMessageLike> Likes { get; set; } = new List<ChatMessageLike>();

    public bool IsDeleted => DeletedAt != null;

    public bool CanEdit(int userId) => SenderId == userId && !IsDeleted;
    public bool CanDelete(int userId) => SenderId == userId && !IsDeleted;

    public void Edit(string content)
    {
        Content = content.Trim();
        EditedAt = DateTime.UtcNow;
    }

    public void SoftDelete()
    {
        DeletedAt = DateTime.UtcNow;
        Content = "[message deleted]";
    }
}