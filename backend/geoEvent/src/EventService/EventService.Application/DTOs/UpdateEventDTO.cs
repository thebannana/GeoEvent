namespace EventService.Application.DTOs;

public class UpdateEventDto
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public int? VenueId { get; set; }
    public int? CityId { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public DateTime? StartDateTime { get; set; }
    public DateTime? EndDateTime { get; set; }
    public int? Capacity { get; set; }
    public decimal? Price { get; set; }
    public bool? IsOnline { get; set; }
    public string? Tags { get; set; }
    public string? ExternalUrl { get; set; }
    public string? AccessibilityInfo { get; set; }
    public string? PromoterName { get; set; }
}
