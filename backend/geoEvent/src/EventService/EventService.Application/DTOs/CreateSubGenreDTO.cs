using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateSubGenreDto
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int GenreId { get; set; }

    public bool IsActive { get; set; } = true;
}

public class UpdateSubGenreDto
{
    [StringLength(100, MinimumLength = 2)]
    public string? Name { get; set; }

    public int? GenreId { get; set; }

    public bool? IsActive { get; set; }
}