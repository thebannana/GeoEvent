using System.ComponentModel.DataAnnotations;

namespace NotificationService.Application.DTOs;

public class NotificationFilterDto
{
    [Range(1, int.MaxValue)]
    public int Page { get; set; } = 1;

    [Range(1, 100)]
    public int PageSize { get; set; } = 20;

    public bool? IsRead { get; set; }
}