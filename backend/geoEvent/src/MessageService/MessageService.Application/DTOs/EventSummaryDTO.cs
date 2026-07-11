namespace MessageService.Application.DTOs;

public class EventSummaryDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public int? OrganizerId { get; set; }
    public string? CoverImageUrl { get; set; }
}