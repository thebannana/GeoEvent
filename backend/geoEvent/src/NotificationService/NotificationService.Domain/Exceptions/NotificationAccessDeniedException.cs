namespace NotificationService.Domain.Exceptions;

public class NotificationAccessDeniedException : Exception
{
    public NotificationAccessDeniedException()
        : base("You do not have access to this notification.") { }
}