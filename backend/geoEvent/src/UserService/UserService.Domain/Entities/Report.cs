using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class Report
{
    public int ReportId { get; set; }
    public ReportTargetType TargetType { get; set; }
    public int? TargetId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public ReportStatus Status { get; set; } = ReportStatus.Pending;
    public int? ReporterId { get; set; }
    public int? ResolvedById { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }


    // Navigation
    public User? Reporter { get; set; }
    public User? ResolvedBy { get; set; }

    // Domain logic
    public void Resolve(int resolvedById)
    {
        Status = ReportStatus.Resolved;
        ResolvedById = resolvedById;
        ResolvedAt = DateTime.UtcNow;
    }

    public void Dismiss(int resolvedById)
    {
        Status = ReportStatus.Dismissed;
        ResolvedById = resolvedById;
        ResolvedAt = DateTime.UtcNow;
    }

    public void StartReview() => Status = ReportStatus.UnderReview;
}
