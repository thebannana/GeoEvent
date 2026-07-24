namespace UserService.Application.DTOs;
public sealed class EventSegmentLookupDto
{
    public int SegmentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Color { get; set; }
    public bool IsActive { get; set; }
    public List<EventGenreLookupDto> Genres { get; set; } = [];
}
