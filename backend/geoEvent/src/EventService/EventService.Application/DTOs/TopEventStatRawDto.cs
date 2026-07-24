namespace EventService.Application.DTOs;

public sealed class TopEventStatRawDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public EventService.Domain.Enums.EventStatus Status { get; set; }
    public DateTime StartDateTime { get; set; }
    public int Count { get; set; }
}