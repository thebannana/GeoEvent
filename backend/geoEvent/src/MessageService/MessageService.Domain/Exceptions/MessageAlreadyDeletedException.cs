namespace MessageService.Domain.Exceptions;

public class MessageAlreadyDeletedException : Exception
{
    public MessageAlreadyDeletedException(int messageId)
        : base($"Message with ID {messageId} has already been deleted.") { }
}