namespace UserService.Application.DTOs;
public sealed class EventGenreLookupDto
{
    public int GenreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SegmentId { get; set; }
    public string? SegmentName { get; set; }
    public bool IsActive { get; set; }
    public List<EventSubGenreLookupDto> SubGenres { get; set; } = [];
}
