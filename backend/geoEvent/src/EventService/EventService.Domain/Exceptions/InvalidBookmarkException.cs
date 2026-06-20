namespace EventService.Domain.Exceptions;

public class InvalidBookmarkException : Exception
{
    public InvalidBookmarkException(string message) : base(message) { }
}