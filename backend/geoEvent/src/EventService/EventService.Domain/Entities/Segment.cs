namespace EventService.Domain.Entities;

public class Segment
{
    public int SegmentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
    public string? Color { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public ICollection<Genre> Genres { get; set; } = [];
    public ICollection<Event> Events { get; set; } = [];
}
