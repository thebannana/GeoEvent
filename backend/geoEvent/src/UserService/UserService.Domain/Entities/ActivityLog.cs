namespace UserService.Domain.Entities;

public class ActivityLog
{
    public int LogId { get; set; }
    public int TargetId { get; set; }
    public int SessionId { get; set; }
    public string ActionType { get; set; } = string.Empty;
    public string TargetType { get; set; } = string.Empty;
    public string Metadata { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation
    public User? User { get; set; }
}
