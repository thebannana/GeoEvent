using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class EventImage
{
    public int ImageId { get; private set; }
    public int EventId { get; private set; }
    public string ImageUrl { get; private set; } = string.Empty;
    public DateTime UploadedAt { get; private set; } = DateTime.UtcNow;
    public bool IsCover { get; private set; }

    public Event? Event { get; private set; }

    private EventImage() { }

    public EventImage(int eventId, string imageUrl, bool isCover = false)
    {
        if (eventId <= 0)
            throw new InvalidEventImageException("EventId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(imageUrl))
            throw new InvalidEventImageException("ImageUrl is required.");

        if (imageUrl.Trim().Length > 1000)
            throw new InvalidEventImageException("ImageUrl cannot be longer than 1000 characters.");

        EventId = eventId;
        ImageUrl = imageUrl.Trim();
        IsCover = isCover;
    }

    public void SetAsCover() => IsCover = true;
    public void RemoveAsCover() => IsCover = false;

    public void UpdateUrl(string imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl))
            throw new InvalidEventImageException("ImageUrl is required.");

        if (imageUrl.Trim().Length > 1000)
            throw new InvalidEventImageException("ImageUrl cannot be longer than 1000 characters.");

        ImageUrl = imageUrl.Trim();
    }
}