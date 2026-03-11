namespace MessageService.Domain.Exceptions;

public class MessageAccessDeniedException : Exception
{
    public MessageAccessDeniedException()
        : base("You do not have access to this message.") { }
}