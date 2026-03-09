namespace EventService.Domain.Entities;

public class Venue
{
    public int VenueId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public int? CityId { get; set; }
    public string? VenueType { get; set; }
    public string? WebsiteUrl { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Description { get; set; }
    public bool IsVerified { get; set; } = false;
    public DateTime CreatedAt { get; set; }
    public string? TimeZone { get; set; }
    public string? Locale { get; set; }


    // Navigation
    public ICollection<Event> Events { get; set; } = [];
    public ICollection<PriceZone> PriceZones { get; set; } = [];
}
