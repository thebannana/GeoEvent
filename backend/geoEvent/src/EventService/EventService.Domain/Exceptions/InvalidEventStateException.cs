namespace EventService.Domain.Exceptions;

public class InvalidEventStateException : Exception
{
    public InvalidEventStateException(string message) : base(message) { }
}