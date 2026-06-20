using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class EventLike
{
    public int LikeId { get; private set; }
    public int EventId { get; private set; }
    public int UserId { get; private set; }
    public DateTime LikedAt { get; private set; } = DateTime.UtcNow;

    public Event? Event { get; private set; }

    private EventLike() { }

    public EventLike(int eventId, int userId)
    {
        if (eventId <= 0)
            throw new InvalidEventLikeException("EventId must be greater than 0.");

        if (userId <= 0)
            throw new InvalidEventLikeException("UserId must be greater than 0.");

        EventId = eventId;
        UserId = userId;
    }
}