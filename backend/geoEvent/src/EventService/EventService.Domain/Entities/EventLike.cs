namespace EventService.Domain.Entities;

public class EventLike
{
    public int LikeId { get; set; }
    public DateTime LikedAt { get; set; } = DateTime.UtcNow;
    public int? EventId { get; set; }
    public int? UserId { get; set; }

    // Navigation
    public Event? Event { get; set; }
}
