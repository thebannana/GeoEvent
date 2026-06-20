namespace EventService.Domain.Exceptions;

public class DuplicateCommentLikeException : Exception
{
    public DuplicateCommentLikeException(int commentId, int userId)
        : base($"User {userId} has already liked comment {commentId}.") { }
}