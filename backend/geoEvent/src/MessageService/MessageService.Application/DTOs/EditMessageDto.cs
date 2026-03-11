using System.ComponentModel.DataAnnotations;

namespace MessageService.Application.DTOs;

public class EditMessageDto
{
    [Required]
    [MinLength(1)]
    [MaxLength(4000)]
    public string Content { get; set; } = string.Empty;
}
