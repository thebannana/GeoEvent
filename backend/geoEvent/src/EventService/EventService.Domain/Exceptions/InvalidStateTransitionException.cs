namespace EventService.Domain.Exceptions;

public class InvalidEventStateTransitionException : Exception
{
    public InvalidEventStateTransitionException(string message)
        : base(message)
    {
    }

    public InvalidEventStateTransitionException(string action, string currentStatus)
        : base($"Event cannot transition via '{action}' from status '{currentStatus}'.")
    {
    }
}