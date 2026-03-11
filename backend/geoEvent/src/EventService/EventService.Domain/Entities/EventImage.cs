namespace EventService.Domain.Entities;

public class EventImage
{
    public int ImageId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public bool IsCover { get; set; } = false;
    public int? EventId { get; set; }

    // Navigation
    public Event? Event { get; set; }

    // Domain logic
    public void SetAsCover() => IsCover = true;
    public void RemoveAsCover() => IsCover = false;
}
