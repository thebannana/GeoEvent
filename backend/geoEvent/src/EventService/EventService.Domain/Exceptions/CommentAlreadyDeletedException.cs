namespace EventService.Domain.Exceptions;

public class CommentAlreadyDeletedException : Exception
{
    public CommentAlreadyDeletedException(int commentId)
        : base($"Comment with ID {commentId} has already been deleted.") { }
}