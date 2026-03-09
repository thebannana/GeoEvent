namespace EventService.Domain.Entities;

public class SubGenre
{
    public int SubGenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int? GenreId { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public Genre? Genre { get; set; }
    public ICollection<Event> Events { get; set; } = [];
}
