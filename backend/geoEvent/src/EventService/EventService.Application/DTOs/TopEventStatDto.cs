namespace EventService.Application.DTOs;
public sealed class TopEventStatDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime StartDateTime { get; set; }
    public int Count { get; set; }
}
