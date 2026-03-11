using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class UpdateBookmarkDto
{
    [MaxLength(500)]
    public string? Memo { get; set; }
}
