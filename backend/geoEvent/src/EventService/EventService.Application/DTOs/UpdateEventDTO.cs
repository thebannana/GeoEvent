using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class UpdateEventDto
{
    [StringLength(200, MinimumLength = 3)]
    public string? Title { get; set; }

    [StringLength(4000, MinimumLength = 10)]
    public string? Description { get; set; }

    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }

    [Range(-90.0, 90.0)]
    public decimal? Latitude { get; set; }

    [Range(-180.0, 180.0)]
    public decimal? Longitude { get; set; }

    public DateTime? StartDateTime { get; set; }
    public DateTime? EndDateTime { get; set; }

    [Range(0, 1_000_000)]
    public int? Capacity { get; set; }

    [Range(0, 100_000)]
    public decimal? Price { get; set; }

    public bool? IsOnline { get; set; }

    [StringLength(500)]
    public string? Tags { get; set; }

    [StringLength(1000)]
    [Url]
    public string? ExternalUrl { get; set; }

    [StringLength(1000)]
    public string? AccessibilityInfo { get; set; }

    [StringLength(200)]
    public string? PromoterName { get; set; }

    [StringLength(10)]
    public string? Locale { get; set; }
}