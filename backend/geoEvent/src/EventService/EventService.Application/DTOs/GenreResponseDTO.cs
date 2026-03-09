namespace EventService.Application.DTOs;

public class GenreResponseDto
{
    public int GenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int? SegmentId { get; set; }
    public bool IsActive { get; set; }
    public List<SubGenreResponseDto> SubGenres { get; set; } = [];
}
