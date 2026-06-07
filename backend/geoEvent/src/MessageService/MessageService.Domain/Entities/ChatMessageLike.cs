namespace MessageService.Domain.Entities;

public class ChatMessageLike
{
    public long MessageId { get; set; }
    public int UserId { get; set; }
    public DateTime LikedAt { get; set; } = DateTime.UtcNow;

    public ChatMessage Message { get; set; } = default!;
}