using EventService.Domain.Enums;
using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class Event
{
    public int EventId { get; private set; }
    public int OrganizerId { get; private set; }

    public int SegmentId { get; private set; }
    public int GenreId { get; private set; }
    public int? SubGenreId { get; private set; }

    public string Title { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;

    public decimal Latitude { get; private set; }
    public decimal Longitude { get; private set; }

    public DateTime StartDateTime { get; private set; }
    public DateTime EndDateTime { get; private set; }

    public int Capacity { get; private set; }
    public decimal Price { get; private set; }

    public EventStatus Status { get; private set; } = EventStatus.Pending;
    public bool IsFeatured { get; private set; }

    public int ViewCount { get; private set; }
    public int LikesCount { get; private set; }

    public string? Tags { get; private set; }
    public string? AccessibilityInfo { get; private set; }
    public string? PromoterName { get; private set; }
    public string Locale { get; private set; } = "bs-BA";

    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; private set; }

    public Segment? Segment { get; private set; }
    public Genre? Genre { get; private set; }
    public SubGenre? SubGenre { get; private set; }

    public ICollection<EventImage> Images { get; private set; } = [];
    public ICollection<EventLike> Likes { get; private set; } = [];
    public ICollection<Bookmark> Bookmarks { get; private set; } = [];
    public ICollection<Comment> Comments { get; private set; } = [];

    private Event() { }

    public Event(
        int organizerId,
        int segmentId,
        int genreId,
        int? subGenreId,
        string title,
        string description,
        decimal latitude,
        decimal longitude,
        DateTime startDateTime,
        DateTime endDateTime,
        int capacity,
        decimal price,
        bool isFeatured,
        string? tags = null,
        string? accessibilityInfo = null,
        string? promoterName = null,
        string? locale = null)
    {
        ValidateCoreData(
            organizerId,
            segmentId,
            genreId,
            title,
            description,
            latitude,
            longitude,
            startDateTime,
            endDateTime,
            capacity,
            price);

        OrganizerId = organizerId;
        SegmentId = segmentId;
        GenreId = genreId;
        SubGenreId = subGenreId;
        Title = title.Trim();
        Description = description.Trim();
        Latitude = latitude;
        Longitude = longitude;
        StartDateTime = startDateTime;
        EndDateTime = endDateTime;
        Capacity = capacity;
        Price = price;
        IsFeatured = isFeatured;
        Tags = Normalize(tags);
        AccessibilityInfo = Normalize(accessibilityInfo);
        PromoterName = Normalize(promoterName);
        Locale = string.IsNullOrWhiteSpace(locale) ? "bs-BA" : locale.Trim();
    }

    public void UpdateDetails(
        int segmentId,
        int genreId,
        int? subGenreId,
        string title,
        string description,
        decimal latitude,
        decimal longitude,
        DateTime startDateTime,
        DateTime endDateTime,
        int capacity,
        decimal price,
        bool isFeatured,
        string? tags = null,
        string? accessibilityInfo = null,
        string? promoterName = null,
        string? locale = null)
    {
        ValidateCoreData(
            OrganizerId,
            segmentId,
            genreId,
            title,
            description,
            latitude,
            longitude,
            startDateTime,
            endDateTime,
            capacity,
            price);

        SegmentId = segmentId;
        GenreId = genreId;
        SubGenreId = subGenreId;
        Title = title.Trim();
        Description = description.Trim();
        Latitude = latitude;
        Longitude = longitude;
        StartDateTime = startDateTime;
        EndDateTime = endDateTime;
        Capacity = capacity;
        Price = price;
        IsFeatured = isFeatured;
        Tags = Normalize(tags);
        AccessibilityInfo = Normalize(accessibilityInfo);
        PromoterName = Normalize(promoterName);
        Locale = string.IsNullOrWhiteSpace(locale) ? "bs-BA" : locale.Trim();
        UpdatedAt = DateTime.UtcNow;
    }

    public bool IsUpcoming() => StartDateTime > DateTime.UtcNow;
    public bool IsPast() => EndDateTime <= DateTime.UtcNow;
    public bool IsActive() => Status == EventStatus.Confirmed;

    public bool CanBePublished() =>
        Status == EventStatus.Pending &&
        !string.IsNullOrWhiteSpace(Title) &&
        !string.IsNullOrWhiteSpace(Description) &&
        StartDateTime > DateTime.UtcNow &&
        EndDateTime > StartDateTime &&
        Capacity >= 0 &&
        Price >= 0;

    public void Publish()
    {
        if (!CanBePublished())
            throw new InvalidEventStateException("Only a valid pending event can be published.");

        Status = EventStatus.Confirmed;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Cancel()
    {
        if (Status is not (EventStatus.Pending or EventStatus.Confirmed))
            throw new InvalidEventStateException("Only pending or confirmed events can be cancelled.");

        Status = EventStatus.Cancelled;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Complete()
    {
        if (Status != EventStatus.Confirmed)
            throw new InvalidEventStateException("Only confirmed events can be completed.");

        Status = EventStatus.Completed;
        UpdatedAt = DateTime.UtcNow;
    }

    public void MarkAsFeatured()
    {
        IsFeatured = true;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UnmarkAsFeatured()
    {
        IsFeatured = false;
        UpdatedAt = DateTime.UtcNow;
    }

    public void IncrementView() => ViewCount++;

    public void IncrementLike() => LikesCount++;
    public void DecrementLike() => LikesCount = Math.Max(0, LikesCount - 1);

    private static void ValidateCoreData(
        int organizerId,
        int segmentId,
        int genreId,
        string title,
        string description,
        decimal latitude,
        decimal longitude,
        DateTime startDateTime,
        DateTime endDateTime,
        int capacity,
        decimal price)
    {
        if (organizerId <= 0)
            throw new InvalidEventDataException("OrganizerId must be greater than 0.");

        if (segmentId <= 0)
            throw new InvalidEventDataException("SegmentId must be greater than 0.");

        if (genreId <= 0)
            throw new InvalidEventDataException("GenreId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(title))
            throw new InvalidEventDataException("Title is required.");

        if (title.Trim().Length > 200)
            throw new InvalidEventDataException("Title cannot be longer than 200 characters.");

        if (string.IsNullOrWhiteSpace(description))
            throw new InvalidEventDataException("Description is required.");

        if (description.Trim().Length > 4000)
            throw new InvalidEventDataException("Description cannot be longer than 4000 characters.");

        if (latitude < -90 || latitude > 90)
            throw new InvalidEventDataException("Latitude must be between -90 and 90.");

        if (longitude < -180 || longitude > 180)
            throw new InvalidEventDataException("Longitude must be between -180 and 180.");

        if (endDateTime <= startDateTime)
            throw new InvalidEventDataException("EndDateTime must be greater than StartDateTime.");

        if (capacity < 0)
            throw new InvalidEventDataException("Capacity cannot be negative.");

        if (price < 0)
            throw new InvalidEventDataException("Price cannot be negative.");
    }

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}