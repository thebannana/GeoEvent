namespace EventService.Domain.Entities;

public class Bookmark
{
    public int BookmarkId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime SavedAt { get; set; }
    public string Memo { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public int? UserId { get; set; }

    // Navigation
    public Event? Event { get; set; }

    // Domain logic
    public void UpdateMemo(string memo) => Memo = memo;
}
