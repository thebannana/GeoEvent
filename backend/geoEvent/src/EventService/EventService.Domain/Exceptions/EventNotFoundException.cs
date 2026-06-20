namespace EventService.Domain.Exceptions;

public class EventNotFoundException : Exception
{
    public EventNotFoundException(int eventId)
        : base($"Event with ID {eventId} was not found.") { }
}