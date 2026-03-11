namespace EventService.Domain.Exceptions;

public class DuplicateLikeException : Exception
{
    public DuplicateLikeException(int eventId, int userId)
        : base($"User {userId} has already liked event {eventId}.") { }
}