namespace EventService.Domain.Exceptions;

public class GenreNotFoundException : Exception
{
    public GenreNotFoundException(int genreId)
        : base($"Genre with ID {genreId} was not found.") { }
}