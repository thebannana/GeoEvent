namespace NotificationService.Application.DTOs;

public class NotificationFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public bool? IsRead { get; set; }
}
