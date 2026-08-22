using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Domain.Entities;

namespace EventService.Application.Interfaces.Repositories;

public interface IEventRepository
{
    Task<List<RankedEvent>> GetNearbyRankedAsync(
        NearbyEventSearchDto dto,
        IReadOnlyList<UserPreferenceDto>? preferences = null);

    Task<List<RankedEvent>> GetPublicRankedAsync(
        EventFilterDto filter,
        IReadOnlyList<UserPreferenceDto> preferences);
    Task<int> GetTotalEventsCountAsync();
    Task<int> GetEventsCountByStatusAsync(EventService.Domain.Enums.EventStatus status);
    Task<int> GetTotalViewsCountAsync();
    Task<List<TopEventStatRawDto>> GetMostLikedEventsAsync(int take);
    Task<List<TopEventStatRawDto>> GetMostViewedEventsAsync(int take);
    Task<List<TopEventStatRawDto>> GetMostCommentedEventsAsync(int take);
    Task<List<TopEventStatRawDto>> GetMostBookmarkedEventsAsync(int take);
    Task<int> GetBookmarksCountAsync();
    Task<int> GetCommentsCountAsync();
    Task<int> GetLikedEventsCountAsync();
    Task<PagedResult<Segment>> GetSegmentsPagedAsync(int page, int pageSize, string? searchTerm);
    Task<PagedResult<Genre>> GetGenresPagedAsync(int page, int pageSize, string? searchTerm);
    Task<PagedResult<SubGenre>> GetSubGenresPagedAsync(int page, int pageSize, string? searchTerm);
    Task<int> CountPublicByOrganizerAsync(int userId);
    Task<Event?> GetTrackedByIdAsync(int eventId);
    Task<Comment?> GetCommentTreeByIdAsync(int commentId);
    Task<HashSet<int>> GetLikedEventIdsAsync(int userId, IEnumerable<int> eventIds);
    Task<HashSet<int>> GetLikedCommentIdsAsync(int userId, IEnumerable<int> commentIds);

    Task<Segment?> GetTrackedSegmentByIdAsync(int segmentId);
    Task<Genre?> GetTrackedGenreByIdAsync(int genreId);
    Task<SubGenre?> GetTrackedSubGenreByIdAsync(int subGenreId);

    Task<Bookmark?> GetTrackedBookmarkByIdAsync(int bookmarkId);
    Task<Comment?> GetTrackedCommentByIdAsync(int commentId);

    Task IncrementViewCountAsync(int eventId);
    Task<List<Event>> GetPublicCandidatesAsync(EventFilterDto filter);

    Task<Event?> GetByIdAsync(int eventId);
    Task<Event?> GetByIdWithDetailsAsync(int eventId);
    Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter);

    Task<Event> CreateAsync(Event entity);
    Task UpdateAsync(Event entity);
    Task<bool> ExistsAsync(int eventId);

    Task<bool> IsLikedByUserAsync(int eventId, int userId);
    Task LikeAsync(int eventId, int userId);
    Task UnlikeAsync(int eventId, int userId);
    Task<PagedResult<EventLike>> GetLikedEventsByUserAsync(int userId, int page, int pageSize);

    Task AddImageAsync(EventImage image, bool setAsCover);
    Task DeleteImageAsync(int imageId);
    Task<EventImage?> GetImageAsync(int imageId);
    Task<List<EventImage>> GetEventImagesAsync(int eventId);
    Task SetCoverImageAsync(int eventId, int imageId);

    Task<List<Segment>> GetAllSegmentsAsync();
    Task<Segment?> GetSegmentByIdAsync(int segmentId);
    Task<Segment> CreateSegmentAsync(Segment segment);
    Task UpdateSegmentAsync(Segment segment);

    Task<List<Genre>> GetGenresBySegmentAsync(int segmentId);
    Task<Genre?> GetGenreByIdAsync(int genreId);
    Task<Genre> CreateGenreAsync(Genre genre);
    Task UpdateGenreAsync(Genre genre);

    Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId);
    Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId);
    Task<SubGenre> CreateSubGenreAsync(SubGenre subGenre);
    Task UpdateSubGenreAsync(SubGenre subGenre);

    Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId);
    Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId);
    Task<PagedResult<Bookmark>> GetUserBookmarksAsync(int userId, int page, int pageSize);
    Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark);
    Task UpdateBookmarkAsync(Bookmark bookmark);
    Task DeleteBookmarkAsync(Bookmark bookmark);

    Task<Comment?> GetCommentByIdAsync(int commentId);
    Task<PagedResult<Comment>> GetEventCommentsAsync(int eventId, int page, int pageSize);
    Task<Comment> CreateCommentAsync(Comment comment);
    Task UpdateCommentAsync(Comment comment);
    Task<PagedResult<Comment>> GetRepliesAsync(int parentCommentId, int page, int pageSize);
    Task<bool> IsCommentLikedByUserAsync(int commentId, int userId);
    Task LikeCommentAsync(int commentId, int userId);
    Task UnlikeCommentAsync(int commentId, int userId);
}