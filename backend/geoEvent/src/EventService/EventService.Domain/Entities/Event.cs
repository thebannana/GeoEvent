using EventService.Domain.Enums;

namespace EventService.Domain.Entities;

public class Event
{
    public int EventId { get; set; }
    public int? OrganizerId { get; set; }
    public int? VenueId { get; set; }
    public int? CityId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public int Capacity { get; set; } = 0;
    public decimal Price { get; set; } = 0;
    public EventStatus Status { get; set; } = EventStatus.Draft;
    public bool IsOnline { get; set; } = false;
    public bool IsFeatured { get; set; } = false;
    public int ViewCount { get; set; } = 0;
    public int LikesCount { get; set; } = 0;
    public string? Tags { get; set; }
    public string? ExternalUrl { get; set; }
    public string? ExternalSource { get; set; }
    public string? ExternalId { get; set; }
    public string? AccessibilityInfo { get; set; }
    public string? PromoterName { get; set; }
    public string Locale { get; set; } = "bs-BA";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }

    public Segment? Segment { get; set; }
    public Genre? Genre { get; set; }
    public SubGenre? SubGenre { get; set; }

    // Navigation
    public Venue? Venue { get; set; }
    public ICollection<EventImage> Images { get; set; } = [];
    public ICollection<EventLike> Likes { get; set; } = [];
    public ICollection<Bookmark> Bookmarks { get; set; } = [];
    public ICollection<Comment> Comments { get; set; } = [];

    // Domain logic
    public bool IsUpcoming() => StartDateTime > DateTime.UtcNow;
    public bool IsPast() => EndDateTime < DateTime.UtcNow;

    public void Cancel()
    {
        Status = EventStatus.Cancelled;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Publish()
    {
        Status = EventStatus.Active;
        UpdatedAt = DateTime.UtcNow;
    }
}
