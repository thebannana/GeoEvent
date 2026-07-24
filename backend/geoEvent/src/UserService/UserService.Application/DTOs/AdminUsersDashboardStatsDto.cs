namespace UserService.Application.DTOs;
public sealed class AdminUsersDashboardStatsDto
{
    public int ActiveUsersCount { get; set; }
    public int TotalReportsCount { get; set; }
    public int BookmarksCount { get; set; }
    public int CommentsCount { get; set; }
    public int LikedEventsCount { get; set; }
    public List<DashboardPreferenceStatDto> TopSegments { get; set; } = [];
    public List<DashboardPreferenceStatDto> TopGenres { get; set; } = [];
    public List<DashboardPreferenceStatDto> TopSubGenres { get; set; } = [];
}
