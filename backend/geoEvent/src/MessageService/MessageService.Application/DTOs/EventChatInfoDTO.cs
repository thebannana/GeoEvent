namespace MessageService.Application.DTOs;

public class EventChatInfoDto
{
    public int EventId { get; set; }
    public string EventTitle { get; set; } = string.Empty;
    public DateTime StartDateTime { get; set; }
    public DateTime? EndDateTime { get; set; }
    public string? CoverImageUrl { get; set; }
}