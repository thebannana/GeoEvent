using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class Report
{
    public int ReportId { get; set; }
    public ReportTargetType TargetType { get; private set; }
    public int? TargetId { get; private set; }
    public string Reason { get; private set; } = string.Empty;
    public ReportStatus Status { get; private set; } = ReportStatus.Pending;
    public int? ReporterId { get; private set; }
    public int? ResolvedById { get; private set; }
    public string Description { get; private set; } = string.Empty;
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; private set; }
    public string? ResolutionNote { get; private set; }
    public string? ModeratorAction { get; private set; }

    public User? Reporter { get; set; }
    public User? ResolvedBy { get; set; }

    private Report() { }

    public Report(
        ReportTargetType targetType,
        int targetId,
        string reason,
        int reporterId,
        string? description = null)
    {
        if (targetId <= 0)
            throw new ArgumentException("Target ID must be greater than zero.", nameof(targetId));

        if (reporterId <= 0)
            throw new ArgumentException("Reporter ID must be greater than zero.", nameof(reporterId));

        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("Reason is required.", nameof(reason));

        TargetType = targetType;
        TargetId = targetId;
        Reason = reason.Trim();
        ReporterId = reporterId;
        Description = string.IsNullOrWhiteSpace(description) ? string.Empty : description.Trim();
        CreatedAt = DateTime.UtcNow;
        Status = ReportStatus.Pending;
    }

    public bool CanStartReview() => Status == ReportStatus.Pending;
    public bool CanResolve() => Status == ReportStatus.Pending || Status == ReportStatus.UnderReview;
    public bool CanDismiss() => Status == ReportStatus.Pending || Status == ReportStatus.UnderReview;

    public void StartReview()
    {
        if (!CanStartReview())
            throw new InvalidOperationException("Only pending reports can enter review.");

        Status = ReportStatus.UnderReview;
    }

    public void Resolve(int resolvedById, string? resolutionNote = null, string? moderatorAction = null)
    {
        if (!CanResolve())
            throw new InvalidOperationException("Report cannot be resolved in its current state.");

        ResolvedById = resolvedById;
        ResolvedAt = DateTime.UtcNow;
        ResolutionNote = string.IsNullOrWhiteSpace(resolutionNote) ? null : resolutionNote.Trim();
        ModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
        Status = ReportStatus.Resolved;
    }

    public void Dismiss(int resolvedById, string? resolutionNote = null, string? moderatorAction = null)
    {
        if (!CanDismiss())
            throw new InvalidOperationException("Report cannot be dismissed in its current state.");

        ResolvedById = resolvedById;
        ResolvedAt = DateTime.UtcNow;
        ResolutionNote = string.IsNullOrWhiteSpace(resolutionNote) ? null : resolutionNote.Trim();
        ModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
        Status = ReportStatus.Dismissed;
    }
}