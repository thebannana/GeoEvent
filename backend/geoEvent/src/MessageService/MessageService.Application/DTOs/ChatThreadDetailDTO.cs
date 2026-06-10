namespace MessageService.Application.DTOs;

public class ChatThreadDetailDto
{
    public long ThreadId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ThreadType { get; set; } = string.Empty;

    public int? EventId { get; set; }
    public string? ImageUrl { get; set; }

    public int? OtherUserId { get; set; }
    public string? OtherUserDisplayName { get; set; }
    public string? OtherUserUsername { get; set; }
    public string? OtherUserAvatarUrl { get; set; }
    public bool? OtherUserIsOnline { get; set; }
    public DateTime? OtherUserLastActiveAt { get; set; }

    public EventChatInfoDto? EventInfo { get; set; }
    public List<ChatParticipantDto> Participants { get; set; } = new();
}