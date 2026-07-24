namespace EventService.Application.DTOs;
public sealed class InternalCommentLookupDto
{
    public int CommentId { get; set; }
    public int EventId { get; set; }
    public int UserId { get; set; }
    public string? Username { get; set; }
    public string? UserDisplayName { get; set; }
    public string Preview { get; set; } = string.Empty;
    public bool IsDeleted { get; set; }
}
