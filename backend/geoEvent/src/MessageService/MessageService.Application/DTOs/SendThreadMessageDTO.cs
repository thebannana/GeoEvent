using System.ComponentModel.DataAnnotations;

namespace MessageService.Application.DTOs;

public class SendThreadMessageDto
{
    [Required]
    [MinLength(1)]
    [MaxLength(4000)]
    public string Content { get; set; } = string.Empty;

    public long? ReplyToMessageId { get; set; }
}