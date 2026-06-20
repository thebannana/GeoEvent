using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class Genre
{
    public int GenreId { get; private set; }
    public int SegmentId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;

    public Segment? Segment { get; private set; }
    public ICollection<SubGenre> SubGenres { get; private set; } = [];
    public ICollection<Event> Events { get; private set; } = [];

    private Genre() { }

    public Genre(int segmentId, string name)
    {
        if (segmentId <= 0)
            throw new InvalidReferenceDataException("SegmentId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("Genre name is required.");

        SegmentId = segmentId;
        Name = name.Trim();
    }

    public void Update(string name, int segmentId)
    {
        if (segmentId <= 0)
            throw new InvalidReferenceDataException("SegmentId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("Genre name is required.");

        SegmentId = segmentId;
        Name = name.Trim();
    }

    public void Activate() => IsActive = true;
    public void Deactivate() => IsActive = false;
}