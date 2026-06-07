namespace EventService.Application.DTOs;

public class CommentResponseDto
{
    public int CommentId { get; set; }
    public string Content { get; set; } = string.Empty;
    public int LikesCount { get; set; }
    public int? UserId { get; set; }
    public int? EventId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public bool IsReply { get; set; }
    public int? ParentCommentId { get; set; }
    public int ReplyCount { get; set; }
    public List<CommentResponseDto> Replies { get; set; } = new();

    public string? Username { get; set; }
    public string? DisplayName { get; set; }
    public string? AvatarUrl { get; set; }

    public bool IsLiked { get; set; }
}