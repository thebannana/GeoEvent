using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class UpdateCommentDto
{
    [Required]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;
}