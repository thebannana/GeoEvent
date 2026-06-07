namespace MessageService.Application.DTOs;

public class SendThreadMessageDto
{
    public string Content { get; set; } = string.Empty;
    public long? ReplyToMessageId { get; set; }
}