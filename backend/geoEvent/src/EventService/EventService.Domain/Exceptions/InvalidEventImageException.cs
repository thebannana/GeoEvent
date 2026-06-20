namespace EventService.Domain.Exceptions;

public class InvalidEventImageException : Exception
{
    public InvalidEventImageException(string message) : base(message) { }
}