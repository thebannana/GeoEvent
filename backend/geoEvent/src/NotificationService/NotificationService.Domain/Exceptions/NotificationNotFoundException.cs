namespace NotificationService.Domain.Exceptions;

public class NotificationNotFoundException : Exception
{
    public NotificationNotFoundException(int notificationId)
        : base($"Notification with ID {notificationId} was not found.") { }
}
