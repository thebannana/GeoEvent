using EventService.Domain.Exceptions;

namespace EventService.Domain.Entities;

public class Comment
{
    public int CommentId { get; private set; }
    public int UserId { get; private set; }
    public int EventId { get; private set; }
    public int? ParentCommentId { get; private set; }

    public string Content { get; private set; } = string.Empty;
    public int LikesCount { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; private set; }
    public bool IsDeleted { get; private set; }

    public Event? Event { get; private set; }
    public Comment? ParentComment { get; private set; }
    public ICollection<Comment> Replies { get; private set; } = [];

    public bool IsReply => ParentCommentId.HasValue;

    private Comment() { }

    public Comment(int userId, int eventId, string content, int? parentCommentId = null)
    {
        if (userId <= 0)
            throw new InvalidCommentException("UserId must be greater than 0.");

        if (eventId <= 0)
            throw new InvalidCommentException("EventId must be greater than 0.");

        if (parentCommentId.HasValue && parentCommentId.Value <= 0)
            throw new InvalidCommentException("ParentCommentId must be greater than 0 when provided.");

        if (string.IsNullOrWhiteSpace(content))
            throw new InvalidCommentException("Comment content is required.");

        if (content.Trim().Length > 1000)
            throw new InvalidCommentException("Comment content cannot be longer than 1000 characters.");

        UserId = userId;
        EventId = eventId;
        ParentCommentId = parentCommentId;
        Content = content.Trim();
    }

    public void Edit(string content)
    {
        if (IsDeleted)
            throw new CommentAlreadyDeletedException(CommentId);

        if (string.IsNullOrWhiteSpace(content))
            throw new InvalidCommentException("Comment content is required.");

        if (content.Trim().Length > 1000)
            throw new InvalidCommentException("Comment content cannot be longer than 1000 characters.");

        Content = content.Trim();
        UpdatedAt = DateTime.UtcNow;
    }

    public void Delete()
    {
        if (IsDeleted)
            return;

        IsDeleted = true;
        UpdatedAt = DateTime.UtcNow;
    }

    public void IncrementLike() => LikesCount++;
    public void DecrementLike() => LikesCount = Math.Max(0, LikesCount - 1);
}