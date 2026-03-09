namespace LocationService.Domain.Entities;

public class PostalCode
{
    public int PostalCodeId { get; set; }
    public string Code { get; set; } = string.Empty;
    public decimal Longitude { get; set; }
    public decimal Latitude { get; set; }
    public int? CityId { get; set; }

    // Navigation
    public City? City { get; set; }
}
