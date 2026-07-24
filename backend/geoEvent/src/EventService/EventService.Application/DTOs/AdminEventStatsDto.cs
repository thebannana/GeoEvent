namespace EventService.Application.DTOs;
public sealed class AdminEventStatsDto
{
    public int TotalEventsCount { get; set; }
    public int ConfirmedEventsCount { get; set; }
    public int PendingEventsCount { get; set; }
    public int CompletedEventsCount { get; set; }
    public int CancelledEventsCount { get; set; }

    public int TotalLikesCount { get; set; }
    public int TotalBookmarksCount { get; set; }
    public int TotalCommentsCount { get; set; }
    public int TotalViewsCount { get; set; }

    public List<TopEventStatDto> MostLikedEvents { get; set; } = [];
    public List<TopEventStatDto> MostViewedEvents { get; set; } = [];
    public List<TopEventStatDto> MostCommentedEvents { get; set; } = [];
    public List<TopEventStatDto> MostBookmarkedEvents { get; set; } = [];
}
