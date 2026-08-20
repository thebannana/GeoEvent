namespace UserService.Application.DTOs;

public class PreferencesFilterDto
{
    public int Page { get; set; } = 1;

    public int PageSize { get; set; } = 20;

    public string? Type { get; set; }

    public double? MinScore { get; set; }

    public double? MaxScore { get; set; }
}