using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateEventDto
{
    [Required]
    [StringLength(200, MinimumLength = 3)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [StringLength(4000, MinimumLength = 10)]
    public string Description { get; set; } = string.Empty;

    [Required]
    public int SegmentId { get; set; }

    [Required]
    public int GenreId { get; set; }

    public int? SubGenreId { get; set; }

    [Required]
    [Range(-90.0, 90.0)]
    public decimal Latitude { get; set; }

    [Required]
    [Range(-180.0, 180.0)]
    public decimal Longitude { get; set; }

    [Required]
    public DateTime StartDateTime { get; set; }

    [Required]
    public DateTime EndDateTime { get; set; }

    [Range(0, 1_000_000)]
    public int Capacity { get; set; } = 0;

    [Range(0, 100_000)]
    public decimal Price { get; set; } = 0;

    [StringLength(500)]
    public string? Tags { get; set; }

    [StringLength(1000)]
    public string? AccessibilityInfo { get; set; }

    [StringLength(200)]
    public string? PromoterName { get; set; }

    [StringLength(10)]
    public string Locale { get; set; } = "bs-BA";
}