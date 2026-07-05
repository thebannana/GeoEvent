namespace MessageService.Application.DTOs;

public sealed class ChatMessagesFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 30;
}