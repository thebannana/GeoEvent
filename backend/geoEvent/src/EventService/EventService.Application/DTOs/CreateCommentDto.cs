using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateCommentDto
{
    [Required]
    public int EventId { get; set; }

    [Required]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;

    public int? ParentCommentId { get; set; }
}