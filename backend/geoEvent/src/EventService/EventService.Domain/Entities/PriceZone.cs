namespace EventService.Domain.Entities;

public class PriceZone
{
    public int PriceZoneId { get; set; }
    public int VenueId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public Venue? Venue { get; set; }
}
