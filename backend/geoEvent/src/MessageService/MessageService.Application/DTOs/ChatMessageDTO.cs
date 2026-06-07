namespace MessageService.Application.DTOs;

public class ChatMessageDto
{
    public long Id { get; set; }
    public long ThreadId { get; set; }
    public int SenderId { get; set; }
    public string SenderDisplayName { get; set; } = string.Empty;
    public string? SenderAvatarUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public DateTime? EditedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    public int LikesCount { get; set; }
    public bool IsLikedByMe { get; set; }
    public ChatReplyPreviewDto? ReplyTo { get; set; }
}