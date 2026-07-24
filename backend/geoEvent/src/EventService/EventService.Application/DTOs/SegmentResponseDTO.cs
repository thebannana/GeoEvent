namespace EventService.Application.DTOs;

public class SegmentResponseDto
{
    public int SegmentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Color { get; set; }
    public bool IsActive { get; set; }
    public List<GenreResponseDto> Genres { get; set; } = [];
}
