namespace EventService.Application.DTOs;

public class NearbyEventSearchDto
{
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public double RadiusKm { get; set; } = 50;
    public int Limit { get; set; } = 20;
}
