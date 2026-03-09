using System.ComponentModel.DataAnnotations;

namespace NotificationService.Application.DTOs;

public class CreateNotificationDto
{
    [Required]
    public int UserId { get; set; }

    [Required]
    [MaxLength(50)]
    public string Type { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(1000)]
    public string Description { get; set; } = string.Empty;
}
