namespace EventService.Domain.Entities;

public class Genre
{
    public int GenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int? SegmentId { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public Segment? Segment { get; set; }
    public ICollection<SubGenre> SubGenres { get; set; } = [];
    public ICollection<Event> Events { get; set; } = [];
}
