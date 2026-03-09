namespace NotificationService.Domain.Exceptions;

public class NotificationQueueNotFoundException : Exception
{
    public NotificationQueueNotFoundException(int queueId)
        : base($"Notification queue item with ID {queueId} was not found.") { }
}
