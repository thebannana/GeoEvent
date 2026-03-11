namespace EventService.Domain.Exceptions;

public class DuplicateBookmarkException : Exception
{
    public DuplicateBookmarkException(int eventId, int userId)
        : base($"User {userId} has already bookmarked event {eventId}.") { }
}