namespace UserService.Application.DTOs.Preferences;

public class PreferencesFilterDto
{
    private const int MaxAllowedPageSize = 100;
    private int _page = 1;
    private int _pageSize = 20;

    public int Page
    {
        get => _page;
        set => _page = value < 1 ? 1 : value;
    }

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value < 1
            ? 20
            : value > MaxAllowedPageSize
                ? MaxAllowedPageSize
                : value;
    }

    public string? Type { get; set; }
    public double? MinScore { get; set; }
    public double? MaxScore { get; set; }
    public string? SearchTerm { get; set; }
    public string SortBy { get; set; } = "score";
    public bool SortDescending { get; set; } = true;
}