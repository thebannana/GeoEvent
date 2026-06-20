namespace EventService.Domain.Exceptions;

public class InvalidCommentException : Exception
{
    public InvalidCommentException(string message) : base(message) { }
}