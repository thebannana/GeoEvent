using System.ComponentModel.DataAnnotations;

namespace MessageService.Application.DTOs;

public class SendMessageDto
{
    [Required]
    public int RecipientId { get; set; }

    public int? EventId { get; set; }

    [Required]
    [MinLength(1)]
    [MaxLength(4000)]
    public string Content { get; set; } = string.Empty;
}
