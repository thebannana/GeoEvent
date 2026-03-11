using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateBookmarkDto
{
    [Required]
    public int EventId { get; set; }

    [MaxLength(500)]
    public string? Memo { get; set; }

}
