using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateSegmentDto
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [StringLength(500)]
    public string? IconUrl { get; set; }

    [StringLength(7)]
    public string? Color { get; set; }

    public bool IsActive { get; set; } = true;
}

public class UpdateSegmentDto
{
    [StringLength(100, MinimumLength = 2)]
    public string? Name { get; set; }

    [StringLength(500)]
    public string? IconUrl { get; set; }

    [StringLength(7)]
    public string? Color { get; set; }

    public bool? IsActive { get; set; }
}