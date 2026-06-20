namespace EventService.Domain.Exceptions;

public class InvalidCommentLikeException : Exception
{
    public InvalidCommentLikeException(string message) : base(message) { }
}