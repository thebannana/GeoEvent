namespace EventService.Domain.Exceptions;

public class EventAccessDeniedException : Exception
{
    public EventAccessDeniedException()
        : base("You do not have permission to modify this event.") { }
}