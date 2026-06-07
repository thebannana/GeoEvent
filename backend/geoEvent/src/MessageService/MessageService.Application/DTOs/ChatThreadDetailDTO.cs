namespace MessageService.Application.DTOs;

public class ChatThreadDetailDto
{
    public long ThreadId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ThreadType { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public EventChatInfoDto? EventInfo { get; set; }
    public List<ChatParticipantDto> Participants { get; set; } = new();
}