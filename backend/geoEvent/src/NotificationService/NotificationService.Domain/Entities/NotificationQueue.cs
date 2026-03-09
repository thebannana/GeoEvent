namespace NotificationService.Domain.Entities;

public class NotificationQueue
{
    public int QueueId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? UserId { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
    public int AttemptCount { get; set; } = 0;
    public string Status { get; set; } = "Pending";
    public string Type { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;

    // Domain logic
    public bool CanRetry() => AttemptCount < 3 && Status == "Failed";

    public void MarkAsSent()
    {
        Status = "Sent";
        ProcessedAt = DateTime.UtcNow;
    }

    public void MarkAsFailed(string errorMessage)
    {
        Status = "Failed";
        ErrorMessage = errorMessage;
        AttemptCount++;
    }

    public void MarkAsProcessing()
    {
        Status = "Processing";
        AttemptCount++;
    }

    public void Cancel() => Status = "Cancelled";
}
