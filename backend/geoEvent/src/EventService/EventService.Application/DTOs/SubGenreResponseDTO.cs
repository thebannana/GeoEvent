namespace EventService.Application.DTOs;

public class SubGenreResponseDto
{
    public int SubGenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int? GenreId { get; set; }
    public bool IsActive { get; set; }
}
