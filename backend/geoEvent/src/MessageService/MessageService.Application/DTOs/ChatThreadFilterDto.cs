namespace MessageService.Application.DTOs;

public sealed class ChatThreadsFilterDto
{
    public string? SearchTerm { get; set; }
    public bool UnreadOnly { get; set; } = false;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}