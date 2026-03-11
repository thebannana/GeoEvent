using NotificationService.Domain.Enums;

namespace NotificationService.Domain.Entities;

public class NotificationQueue
{
    public int QueueId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int? UserId { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
    public int AttemptCount { get; set; } = 0;
    public NotificationQueueStatus Status { get; set; } = NotificationQueueStatus.Pending;
    public NotificationType Type { get; set; }
    public string Payload { get; set; } = string.Empty;
    public int MaxAttempts { get; set; } = 3;

    // Domain logic
    public bool CanRetry() =>
        AttemptCount < MaxAttempts &&
        Status == NotificationQueueStatus.Failed;

    public bool IsOverdue() =>
        Status == NotificationQueueStatus.Pending &&
        ScheduledAt < DateTime.UtcNow;

    public void MarkAsSent()
    {
        Status = NotificationQueueStatus.Sent;
        ProcessedAt = DateTime.UtcNow;
    }

    public void MarkAsFailed(string errorMessage)
    {
        Status = NotificationQueueStatus.Failed;
        ErrorMessage = errorMessage;
        AttemptCount++;
    }

    public void MarkAsProcessing()
    {
        Status = NotificationQueueStatus.Processing;
        AttemptCount++;
    }

    public void Cancel() => Status = NotificationQueueStatus.Cancelled;

    public void ResetForRetry()
    {
        Status = NotificationQueueStatus.Retrying;
        ErrorMessage = string.Empty;
    }

}
