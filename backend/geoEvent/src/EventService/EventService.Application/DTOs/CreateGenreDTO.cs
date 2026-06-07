using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateGenreDto
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int SegmentId { get; set; }

    public bool IsActive { get; set; } = true;
}

public class UpdateGenreDto
{
    [StringLength(100, MinimumLength = 2)]
    public string? Name { get; set; }

    public int? SegmentId { get; set; }

    public bool? IsActive { get; set; }
}