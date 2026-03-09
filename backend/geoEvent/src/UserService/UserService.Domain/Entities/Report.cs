namespace UserService.Domain.Entities;

public class Report
{
    public int ReportId { get; set; }
    public string TargetType { get; set; } = string.Empty;
    public int? TargetId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending";
    public int? ReporterId { get; set; }
    public int? ResolvedById { get; set; }
    public string Description { get; set; } = string.Empty;

    // Navigation
    public User? Reporter { get; set; }
    public User? ResolvedBy { get; set; }

    // Domain logic
    public void Resolve(int resolvedById)
    {
        Status = "Resolved";
        ResolvedById = resolvedById;
    }

    public void Dismiss(int resolvedById)
    {
        Status = "Dismissed";
        ResolvedById = resolvedById;
    }

    public void StartReview() => Status = "UnderReview";
}
