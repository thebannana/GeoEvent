using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class CommentLike
{
    public int LikeId { get; private set; }
    public int CommentId { get; private set; }
    public int UserId { get; private set; }
    public DateTime LikedAt { get; private set; } = DateTime.UtcNow;

    public Comment? Comment { get; private set; }

    private CommentLike() { }

    public CommentLike(int commentId, int userId)
    {
        if (commentId <= 0)
            throw new InvalidCommentLikeException("CommentId must be greater than 0.");

        if (userId <= 0)
            throw new InvalidCommentLikeException("UserId must be greater than 0.");

        CommentId = commentId;
        UserId = userId;
    }
}