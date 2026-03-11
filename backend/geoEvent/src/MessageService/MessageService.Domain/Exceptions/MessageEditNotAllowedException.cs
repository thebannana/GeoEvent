namespace MessageService.Domain.Exceptions;

public class MessageEditNotAllowedException : Exception
{
    public MessageEditNotAllowedException()
        : base("You can only edit your own messages.") { }
}