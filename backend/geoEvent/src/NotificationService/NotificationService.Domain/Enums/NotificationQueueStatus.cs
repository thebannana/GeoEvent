namespace NotificationService.Domain.Enums;

public enum NotificationQueueStatus
{
    Pending,
    Processing,
    Sent,
    Failed,
    Cancelled
}
