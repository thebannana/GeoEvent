using NotificationService.Domain.Enums;

namespace NotificationService.Application.DTOs;

public class QueueFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public NotificationQueueStatus? Status { get; set; }
    public NotificationType? Type { get; set; }
}
