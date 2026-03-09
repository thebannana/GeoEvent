namespace NotificationService.Application.DTOs;

public class NotificationQueueResponseDto
{
    public int QueueId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? UserId { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
    public int AttemptCount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;
}
