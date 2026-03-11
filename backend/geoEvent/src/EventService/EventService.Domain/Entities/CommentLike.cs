namespace EventService.Domain.Entities;

public class CommentLike
{
    public int LikeId { get; set; }
    public int CommentId { get; set; }
    public int UserId { get; set; }
    public DateTime LikedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public Comment? Comment { get; set; }
}