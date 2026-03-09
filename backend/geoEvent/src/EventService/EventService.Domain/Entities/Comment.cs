namespace EventService.Domain.Entities;

public class Comment
{
    public int CommentId { get; set; }
    public string Content { get; set; } = string.Empty;
    public int LikesCount { get; set; } = 0;
    public int? UserId { get; set; }
    public int? EventId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; } = false;
    public int? ParentCommentId { get; set; }

    // Navigation
    public Event? Event { get; set; }
    public Comment? ParentComment { get; set; }
    public ICollection<Comment> Replies { get; set; } = [];

    // Domain logic
    public void Edit(string content)
    {
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
