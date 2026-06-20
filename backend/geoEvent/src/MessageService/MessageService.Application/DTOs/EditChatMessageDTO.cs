using System.ComponentModel.DataAnnotations;

namespace MessageService.Application.DTOs;

public class EditChatMessageDto
{
    [Required]
    [MinLength(1)]
    [MaxLength(4000)]
    public string Content { get; set; } = string.Empty;
}