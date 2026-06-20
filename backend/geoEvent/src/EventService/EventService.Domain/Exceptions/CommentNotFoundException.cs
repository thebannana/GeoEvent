namespace EventService.Domain.Exceptions;

public class CommentNotFoundException : Exception
{
    public CommentNotFoundException(int commentId)
        : base($"Comment with ID {commentId} was not found.") { }
}