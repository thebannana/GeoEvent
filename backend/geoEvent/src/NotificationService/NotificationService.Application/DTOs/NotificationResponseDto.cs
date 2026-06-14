namespace NotificationService.Application.DTOs;

public class NotificationResponseDto
{
    public int NotificationId { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public bool IsRead { get; set; }
    public int? UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReadAt { get; set; }
}