namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedReportOptions
{
    public int ReporterId { get; set; }
    public string TargetType { get; set; } = "User"; // "User", "Event", "Comment", "Review"
    public int TargetId { get; set; }
    public string Reason { get; set; } = "Inappropriate content";
    public string? Description { get; set; }
    public string Status { get; set; } = "Pending"; // "Pending", "UnderReview", "Resolved", "Dismissed"
    public int? ResolvedById { get; set; }
    public string? ResolutionNote { get; set; }
    public string? ModeratorAction { get; set; }
}