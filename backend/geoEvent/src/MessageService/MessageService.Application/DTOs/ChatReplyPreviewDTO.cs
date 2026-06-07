namespace MessageService.Application.DTOs;

public class ChatReplyPreviewDto
{
    public long MessageId { get; set; }
    public int SenderId { get; set; }
    public string SenderDisplayName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}