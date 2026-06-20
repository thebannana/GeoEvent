using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class SubGenre
{
    public int SubGenreId { get; private set; }
    public int GenreId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;

    public Genre? Genre { get; private set; }
    public ICollection<Event> Events { get; private set; } = [];

    private SubGenre() { }

    public SubGenre(int genreId, string name)
    {
        if (genreId <= 0)
            throw new InvalidReferenceDataException("GenreId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("SubGenre name is required.");

        GenreId = genreId;
        Name = name.Trim();
    }

    public void Update(string name, int genreId)
    {
        if (genreId <= 0)
            throw new InvalidReferenceDataException("GenreId must be greater than 0.");

        if (string.IsNullOrWhiteSpace(name))
            throw new InvalidReferenceDataException("SubGenre name is required.");

        GenreId = genreId;
        Name = name.Trim();
    }

    public void Activate() => IsActive = true;
    public void Deactivate() => IsActive = false;
}