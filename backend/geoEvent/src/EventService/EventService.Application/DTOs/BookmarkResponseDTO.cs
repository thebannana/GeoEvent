namespace EventService.Application.DTOs;

public class BookmarkResponseDto
{
    public int BookmarkId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime SavedAt { get; set; }
    public string Memo { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public int? UserId { get; set; }
}
