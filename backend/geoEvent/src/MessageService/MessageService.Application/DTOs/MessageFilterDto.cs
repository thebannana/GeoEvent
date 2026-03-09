namespace MessageService.Application.DTOs;

public class MessageFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public bool? IsRead { get; set; }
}
