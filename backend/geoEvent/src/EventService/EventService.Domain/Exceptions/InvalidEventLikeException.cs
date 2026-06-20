namespace EventService.Domain.Exceptions;

public class InvalidEventLikeException : Exception
{
    public InvalidEventLikeException(string message) : base(message) { }
}