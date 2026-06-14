namespace TicketService.Application.DTOs;

public class EventSummaryDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int? OrganizerId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public string? CoverImageUrl { get; set; }
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public string? VenueName { get; set; }
    public bool IsOnline { get; set; }
}