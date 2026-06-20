namespace EventService.Domain.Exceptions;

public class EventCapacityExceededException : Exception
{
    public EventCapacityExceededException(int eventId)
        : base($"Event with ID {eventId} has reached maximum capacity.") { }
}