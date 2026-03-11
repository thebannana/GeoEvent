using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class ActivityLog
{
    public int LogId { get; set; }
    public int TargetId { get; set; }
    public Guid SessionId { get; set; }
    public ActivityActionType ActionType { get; set; }
    public ActivityTargetType TargetType { get; set; }
    public string Metadata { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation
    public User? User { get; set; }
}
