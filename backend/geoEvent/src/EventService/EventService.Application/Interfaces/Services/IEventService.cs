using EventService.Application.Common;
using EventService.Application.DTOs;

namespace EventService.Application.Interfaces.Services;

public interface IEventService
{
    Task<ServiceResult<InternalEventLookupDto>> GetInternalEventLookupAsync(int eventId);
    Task<ServiceResult<InternalCommentLookupDto>> GetInternalCommentLookupAsync(int commentId);
    Task<ServiceResult<CommentResponseDto>> AdminUpdateCommentAsync(int commentId, UpdateCommentDto dto);
    Task<ServiceResult<bool>> AdminDeleteCommentAsync(int commentId);
    Task<ServiceResult<EventResponseDto>> GetAdminByIdAsync(int eventId);
    Task<ServiceResult<EventResponseDto>> AdminUpdateAsync(int eventId, UpdateEventDto dto);
    Task<ServiceResult<bool>> AdminDeleteAsync(int eventId);
    Task<ServiceResult<AdminEventStatsDto>> GetAdminEventStatsAsync();
    Task<ServiceResult<InternalEventEngagementStatsDto>> GetInternalEngagementStatsAsync();
    Task<ServiceResult<PagedResultSegmentResponseDto>> GetSegmentsPagedAsync(int page, int pageSize, string? searchTerm);
    Task<ServiceResult<PagedResultGenreResponseDto>> GetGenresPagedAsync(int page, int pageSize, string? searchTerm);
    Task<ServiceResult<PagedResultSubGenreResponseDto>> GetSubGenresPagedAsync(int page, int pageSize, string? searchTerm);
    Task<ServiceResult<int>> GetPublicCountByOrganizerAsync(int userId);
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetPublicAsync(EventFilterDto filter, int? requesterId = null);
    Task<ServiceResult<EventResponseDto>> GetPublicByIdAsync(int eventId, int? requesterId = null);
    Task<ServiceResult<List<EventResponseDto>>> GetNearbyPublicAsync(NearbyEventSearchDto dto);
    Task<ServiceResult<PagedResult<LikedEventResponseDto>>> GetLikedEventsAsync(int userId, int page, int pageSize);

    Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter);
    Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId);
    Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId);
    Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CompleteAsync(int eventId, int requesterId);

    Task<ServiceResult<bool>> LikeAsync(int eventId, int userId);
    Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId);

    Task<ServiceResult<bool>> AddImageAsync(int eventId, string imageUrl, bool isCover, int requesterId);
    Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId);
    Task<ServiceResult<bool>> SetCoverImageAsync(int eventId, int imageId, int requesterId);

    Task<ServiceResult<List<SegmentResponseDto>>> GetAllSegmentsAsync();
    Task<ServiceResult<SegmentResponseDto>> GetSegmentByIdAsync(int segmentId);
    Task<ServiceResult<SegmentResponseDto>> CreateSegmentAsync(CreateSegmentDto dto);
    Task<ServiceResult<SegmentResponseDto>> UpdateSegmentAsync(int segmentId, UpdateSegmentDto dto);

    Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId);
    Task<ServiceResult<GenreResponseDto>> GetGenreByIdAsync(int genreId);
    Task<ServiceResult<GenreResponseDto>> CreateGenreAsync(CreateGenreDto dto);
    Task<ServiceResult<GenreResponseDto>> UpdateGenreAsync(int genreId, UpdateGenreDto dto);

    Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId);
    Task<ServiceResult<SubGenreResponseDto>> GetSubGenreByIdAsync(int subGenreId);
    Task<ServiceResult<SubGenreResponseDto>> CreateSubGenreAsync(CreateSubGenreDto dto);
    Task<ServiceResult<SubGenreResponseDto>> UpdateSubGenreAsync(int subGenreId, UpdateSubGenreDto dto);

    Task<ServiceResult<PagedResult<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId, BookmarkFilterDto filter);
    Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId);
    Task<ServiceResult<BookmarkResponseDto>> UpdateBookmarkAsync(int bookmarkId, UpdateBookmarkDto dto, int userId);
    Task<ServiceResult<bool>> DeleteBookmarkAsync(int bookmarkId, int userId);

    Task<ServiceResult<CommentResponseDto>> GetCommentByIdAsync(int commentId, int? requesterId = null);
    Task<ServiceResult<PagedResult<CommentResponseDto>>> GetEventCommentsAsync(int eventId,int page,int pageSize,int? requesterId = null);
    Task<ServiceResult<PagedResult<CommentResponseDto>>> GetRepliesAsync(int commentId, int page, int pageSize, int? requesterId = null);
    Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId);
    Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId);
    Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId);
    Task<ServiceResult<CommentResponseDto>> LikeCommentAsync(int commentId, int userId);
    Task<ServiceResult<CommentResponseDto>> UnlikeCommentAsync(int commentId, int userId);
}