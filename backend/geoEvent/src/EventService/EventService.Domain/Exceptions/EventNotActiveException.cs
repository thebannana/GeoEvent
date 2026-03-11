namespace EventService.Domain.Exceptions;

public class EventNotActiveException : Exception
{
    public EventNotActiveException(int eventId)
        : base($"Event with ID {eventId} is not active.") { }
}