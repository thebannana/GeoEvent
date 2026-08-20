namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedEventOptions
{
    public string? OrganizerUsername { get; set; }

    public int? OrganizerId { get; set; }

    public int SegmentId { get; set; }
    public int GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public string Title { get; set; } = "Event";
    public string Description { get; set; } = "Event description";
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public int Capacity { get; set; } = 100;
    public decimal Price { get; set; } = 0m;
    public string Status { get; set; } = "Confirmed";
    public bool IsFeatured { get; set; }
    public string? Tags { get; set; }
    public string? AccessibilityInfo { get; set; }
    public string? PromoterName { get; set; }
    public string Locale { get; set; } = "bs-BA";
}