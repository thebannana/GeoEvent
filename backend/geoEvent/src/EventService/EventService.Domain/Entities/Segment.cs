using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class Segment
{
    public int SegmentId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string? IconUrl { get; private set; }
    public string? Color { get; private set; }
    public bool IsActive { get; private set; } = true;

    public ICollection<Genre> Genres { get; private set; } = [];
    public ICollection<Event> Events { get; private set; } = [];

    private Segment() { }

    public Segment(string name, string? iconUrl = null, string? color = null)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("Segment name is required.");

        Name = name.Trim();
        IconUrl = Normalize(iconUrl);
        Color = Normalize(color);
    }

    public void Update(string name, string? iconUrl, string? color)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("Segment name is required.");

        Name = name.Trim();
        IconUrl = Normalize(iconUrl);
        Color = Normalize(color);
    }

    public void Activate() => IsActive = true;
    public void Deactivate() => IsActive = false;

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}