using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class NearbyEventSearchDto
{
    [Required]
    public decimal? Latitude { get; set; }

    [Required]
    public decimal? Longitude { get; set; }

    public double RadiusKm { get; set; } = 50;
    public int Limit { get; set; } = 20;
}
