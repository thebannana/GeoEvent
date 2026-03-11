namespace LocationService.Application.DTOs;

public class NearbySearchDto
{
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public double RadiusKm { get; set; } = 50;
    public int Limit { get; set; } = 10;
}
