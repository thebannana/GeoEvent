using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreatePriceZoneDto
{
    [Required]
    public int VenueId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }
}
