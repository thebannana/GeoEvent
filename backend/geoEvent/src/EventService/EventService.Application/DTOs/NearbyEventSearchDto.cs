using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public sealed class NearbyEventSearchDto
{
    [Range(-90, 90)]
    public decimal? Latitude { get; set; }

    [Range(-180, 180)]
    public decimal? Longitude { get; set; }

    [Range(1, 500)]
    public double RadiusKm { get; set; } = 50;

    [Range(1, 100)]
    public int Limit { get; set; } = 20;

    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }

    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }

    public bool TodayOnly { get; set; }

    public bool UsePreferences { get; set; }
}