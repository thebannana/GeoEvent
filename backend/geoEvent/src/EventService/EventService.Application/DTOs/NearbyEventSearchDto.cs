using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class NearbyEventSearchDto
{
    [Required] public decimal? Latitude { get; set; }
    [Required] public decimal? Longitude { get; set; }
    public double RadiusKm { get; set; } = 50;
    public int Limit { get; set; } = 20;
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool TodayOnly { get; set; } = false;
}