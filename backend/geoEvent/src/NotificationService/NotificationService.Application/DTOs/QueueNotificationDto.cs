using NotificationService.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace NotificationService.Application.DTOs;

public class QueueNotificationDto
{
    [Required]
    public int UserId { get; set; }

    [Required]
    public NotificationType Type { get; set; }

    [Required]
    public string Payload { get; set; } = string.Empty;

    public DateTime? ScheduledAt { get; set; }
}
