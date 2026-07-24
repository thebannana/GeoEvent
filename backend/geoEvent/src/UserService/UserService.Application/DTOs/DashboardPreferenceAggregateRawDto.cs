namespace UserService.Application.DTOs;

public sealed class DashboardPreferenceAggregateRawDto
{
    public int Id { get; set; }
    public double TotalScore { get; set; }
    public int UserCount { get; set; }
}