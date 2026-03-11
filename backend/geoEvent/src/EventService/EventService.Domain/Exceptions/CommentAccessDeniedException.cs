namespace EventService.Domain.Exceptions;

public class CommentAccessDeniedException : Exception
{
    public CommentAccessDeniedException()
        : base("You do not have permission to modify this comment.") { }
}