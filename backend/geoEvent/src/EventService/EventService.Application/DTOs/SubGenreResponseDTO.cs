namespace EventService.Application.DTOs;

public class SubGenreResponseDto
{
    public int SubGenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int GenreId { get; set; }
    public string? GenreName { get; set; }
    public int? SegmentId { get; set; }
    public string? SegmentName { get; set; }
    public bool IsActive { get; set; }
}
