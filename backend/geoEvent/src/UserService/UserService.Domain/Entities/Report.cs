using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class Report
{
    public int ReportId { get; private set; }
    public ReportTargetType TargetType { get; private set; }
    public int? TargetId { get; private set; }
    public string Reason { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public ReportStatus Status { get; private set; }
    public int ReporterId { get; private set; }
    public int? ResolvedById { get; private set; }
    public string? ResolutionNote { get; private set; }
    public string? ModeratorAction { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ResolvedAt { get; private set; }

    public User? Reporter { get; private set; }
    public User? ResolvedBy { get; private set; }

    public User? TargetUser { get; private set; }

    protected Report() { }

    public Report(
        ReportTargetType targetType,
        int targetId,
        string reason,
        int reporterId,
        string? description = null)
    {
        TargetType = targetType;
        TargetId = targetId;
        Reason = reason.Trim();
        ReporterId = reporterId;
        Description = string.IsNullOrWhiteSpace(description) ? null : description.Trim();
        Status = ReportStatus.Pending;
        CreatedAt = DateTime.UtcNow;
    }

    public void MarkUnderReview(int adminUserId, string? resolutionNote, string? moderatorAction)
    {
        Status = ReportStatus.UnderReview;
        ResolvedById = adminUserId;
        ResolvedAt = null;
        ResolutionNote = string.IsNullOrWhiteSpace(resolutionNote) ? null : resolutionNote.Trim();
        ModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void Resolve(int adminUserId, string? resolutionNote, string? moderatorAction)
    {
        Status = ReportStatus.Resolved;
        ResolvedById = adminUserId;
        ResolvedAt = DateTime.UtcNow;
        ResolutionNote = string.IsNullOrWhiteSpace(resolutionNote) ? null : resolutionNote.Trim();
        ModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void Dismiss(int adminUserId, string? resolutionNote, string? moderatorAction)
    {
        Status = ReportStatus.Dismissed;
        ResolvedById = adminUserId;
        ResolvedAt = DateTime.UtcNow;
        ResolutionNote = string.IsNullOrWhiteSpace(resolutionNote) ? null : resolutionNote.Trim();
        ModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }
}