namespace MessageService.Domain.Exceptions;

public class MessageNotFoundException : Exception
{
    public MessageNotFoundException(int messageId)
        : base($"Message with ID {messageId} was not found.") { }
}
