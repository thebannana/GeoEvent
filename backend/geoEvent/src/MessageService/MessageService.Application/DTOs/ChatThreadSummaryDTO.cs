namespace MessageService.Application.DTOs;

public class ChatThreadSummaryDto
{
    public long ThreadId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ThreadType { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public string? ImageUrl { get; set; }
    public string? LastMessageContent { get; set; }
    public DateTime? LastMessageSentAt { get; set; }
    public int UnreadCount { get; set; }
    public bool IsGroup { get; set; }
    public int? OtherUserId { get; set; }
    public string? OtherUserDisplayName { get; set; }
    public string? OtherUserAvatarUrl { get; set; }
    public bool? OtherUserIsOnline { get; set; }
    public DateTime? OtherUserLastActiveAt { get; set; }
    public string? OtherUserUsername { get; set; }
}