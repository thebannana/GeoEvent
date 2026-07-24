namespace UserService.Application.DTOs;

public class AdminReportResponseDto
{
    public int ReportId { get; set; }

    public string TargetType { get; set; } = string.Empty;
    public int? TargetId { get; set; }

    public string TargetDisplay { get; set; } = string.Empty;
    public string? TargetUsername { get; set; }

    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; } = string.Empty;
    public string Preview { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public int? ReporterId { get; set; }
    public string ReporterUsername { get; set; } = string.Empty;
    public string ReporterDisplayName { get; set; } = string.Empty;

    public int? ResolvedById { get; set; }
    public string? ResolvedByUsername { get; set; }
    public string? ResolvedByDisplayName { get; set; }

    public string? ResolutionNote { get; set; }
    public string? ModeratorAction { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
}