namespace EventService.Application.DTOs;

public class CommentResponseDto
{
    public int CommentId { get; set; }
    public string Content { get; set; } = string.Empty;   // service replaces with "[deleted]" when IsDeleted
    public int LikesCount { get; set; }
    public int? UserId { get; set; }
    public int? EventId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public bool IsReply { get; set; }                     // new
    public int? ParentCommentId { get; set; }
    public int ReplyCount { get; set; }                   // new — avoid loading all replies recursively
    public List<CommentResponseDto> Replies { get; set; } = [];
}
