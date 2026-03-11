namespace NotificationService.Domain.Enums;

public enum NotificationQueueStatus
{
    Pending,
    Processing,
    Retrying,
    Sent,
    Failed,
    Cancelled
}

