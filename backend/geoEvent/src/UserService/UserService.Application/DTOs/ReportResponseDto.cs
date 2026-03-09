namespace UserService.Application.DTOs;

public class ReportResponseDto
{
    public int ReportId { get; set; }
    public string TargetType { get; set; } = string.Empty;
    public int? TargetId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int? ReporterId { get; set; }
    public int? ResolvedById { get; set; }
    public string Description { get; set; } = string.Empty;
}
