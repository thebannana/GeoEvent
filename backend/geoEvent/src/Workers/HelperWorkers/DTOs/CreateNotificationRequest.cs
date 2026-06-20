using Shared.Contracts.Enums;

namespace GeoEvent.HelperWorkers.DTOs;

public class CreateNotificationRequest
{
    public int UserId { get; set; }
    public NotificationType Type { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
}