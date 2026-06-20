namespace EventService.Domain.Exceptions;

public class SubGenreNotFoundException : Exception
{
    public SubGenreNotFoundException(int subGenreId)
        : base($"SubGenre with ID {subGenreId} was not found.") { }
}