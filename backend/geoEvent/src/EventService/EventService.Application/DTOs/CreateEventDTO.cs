using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateEventDto
{
    [Required]
    [StringLength(200, MinimumLength = 3)]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Description { get; set; } = string.Empty;

    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public int? VenueId { get; set; }
    public int? CityId { get; set; }

    [Required]
    public decimal Latitude { get; set; }

    [Required]
    public decimal Longitude { get; set; }

    [Required]
    public DateTime StartDateTime { get; set; }

    [Required]
    public DateTime EndDateTime { get; set; }

    public int Capacity { get; set; } = 0;
    public decimal Price { get; set; } = 0;
    public bool IsOnline { get; set; } = false;
    public string? Tags { get; set; }
    public string? ExternalUrl { get; set; }
    public string? AccessibilityInfo { get; set; }
    public string? PromoterName { get; set; }
    public string Locale { get; set; } = "bs-BA";
}
