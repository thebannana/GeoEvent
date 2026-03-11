using EventService.Domain.Enums;

namespace EventService.Domain.Entities;

public class Comment
{
    public int CommentId { get; set; }
    public string Content { get; set; } = string.Empty;
    public int LikesCount { get; set; } = 0;
    public int? UserId { get; set; }
    public int? EventId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; } = false;       // keep — matches migration column
    public int? ParentCommentId { get; set; }

    // Navigation
    public Event? Event { get; set; }
    public Comment? ParentComment { get; set; }
    public ICollection<Comment> Replies { get; set; } = [];

    // Domain logic
    public bool IsReply => ParentCommentId is not null;
    public bool IsTopLevel => ParentCommentId is null;

    public void Edit(string content)
    {
        if (IsDeleted)
            throw new InvalidOperationException("Cannot edit a deleted comment.");
        if (string.IsNullOrWhiteSpace(content))
            throw new ArgumentException("Comment content cannot be empty.");
        Content = content;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Delete()
    {
        IsDeleted = true;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Like() => LikesCount++;
    public void Unlike() => LikesCount = Math.Max(0, LikesCount - 1);
}
