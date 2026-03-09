namespace EventService.Application.DTOs;

public class EventResponseDto
{
    public int EventId { get; set; }
    public int? OrganizerId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public int? VenueId { get; set; }
    public int? CityId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public int Capacity { get; set; }
    public decimal Price { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool IsOnline { get; set; }
    public bool IsFeatured { get; set; }
    public int ViewCount { get; set; }
    public int LikesCount { get; set; }
    public string? Tags { get; set; }
    public string? ExternalUrl { get; set; }
    public string? AccessibilityInfo { get; set; }
    public string? PromoterName { get; set; }
    public string Locale { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public List<string> ImageUrls { get; set; } = [];
    public string? CoverImageUrl { get; set; }
}
