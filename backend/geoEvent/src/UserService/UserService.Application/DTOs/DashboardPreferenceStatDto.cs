namespace UserService.Application.DTOs;
public sealed class DashboardPreferenceStatDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ParentName { get; set; }
    public string? Color { get; set; }
    public double TotalScore { get; set; }
    public int UserCount { get; set; }
}
