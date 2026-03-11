namespace NotificationService.Domain.Exceptions;

public class NotificationAlreadyReadException : Exception
{
    public NotificationAlreadyReadException(int notificationId)
        : base($"Notification with ID {notificationId} has already been read.") { }
}