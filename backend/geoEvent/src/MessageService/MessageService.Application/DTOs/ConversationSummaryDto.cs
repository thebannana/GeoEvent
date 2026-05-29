namespace MessageService.Application.DTOs;

public class ConversationSummaryDto
{
    public int OtherUserId { get; set; }
    public string OtherUserDisplayName { get; set; } = string.Empty;
    public string? OtherUserAvatarUrl { get; set; }
    public string LastMessageContent { get; set; } = string.Empty;
    public DateTime LastMessageSentAt { get; set; }
    public int UnreadCount { get; set; }
    public bool IsLastMessageFromMe { get; set; }
}