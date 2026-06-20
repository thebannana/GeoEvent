using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class Bookmark
{
    public int BookmarkId { get; private set; }
    public int EventId { get; private set; }
    public int UserId { get; private set; }
    public DateTime SavedAt { get; private set; } = DateTime.UtcNow;
    public string? Memo { get; private set; }

    public Event? Event { get; private set; }

    private Bookmark() { }

    public Bookmark(int eventId, int userId, string? memo = null)
    {
        if (eventId <= 0)
            throw new InvalidBookmarkException("EventId must be greater than 0.");

        if (userId <= 0)
            throw new InvalidBookmarkException("UserId must be greater than 0.");

        EventId = eventId;
        UserId = userId;
        Memo = Normalize(memo);
    }

    public void UpdateMemo(string? memo)
    {
        Memo = Normalize(memo);
    }

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}