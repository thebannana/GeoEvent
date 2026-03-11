using MessageService.Domain.Enums;

namespace MessageService.Application.DTOs;

public class MessageFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public bool? IsRead { get; set; }
    public int? EventId { get; set; }
    public MessageSortOrder SortOrder { get; set; } = MessageSortOrder.Newest;
}
