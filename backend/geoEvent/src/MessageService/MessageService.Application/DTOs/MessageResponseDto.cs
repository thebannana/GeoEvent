namespace MessageService.Application.DTOs;

public class MessageResponseDto
{
    public int Id { get; set; }
    public int SenderId { get; set; }
    public int RecipientId { get; set; }
    public int? EventId { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public int LikesCount { get; set; }
    public DateTime SentAt { get; set; }
    public DateTime? ReadAt { get; set; }
    public DateTime? EditedAt { get; set; }

    public string SenderDisplayName { get; set; } = string.Empty;
    public string? SenderAvatarUrl { get; set; }
    public string RecipientDisplayName { get; set; } = string.Empty;
    public string? RecipientAvatarUrl { get; set; }
}