namespace MessageService.Domain.Exceptions;

public class CannotMessageYourselfException : Exception
{
    public CannotMessageYourselfException()
        : base("You cannot send a message to yourself.") { }
}