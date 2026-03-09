using EventService.Application.Common;
using EventService.Application.DTOs;

namespace EventService.Application.Interfaces.Services;

public interface IEventService
{
    Task<ServiceResult<EventResponseDto>> GetByIdAsync(int eventId);
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter);
    Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId);
    Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId);
    Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> LikeAsync(int eventId, int userId);
    Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId);
    Task<ServiceResult<bool>> AddImageAsync(int eventId, string imageUrl, bool isCover);
    // ── Segments ──────────────────────────────────────────────────
    Task<ServiceResult<List<SegmentResponseDto>>> GetAllSegmentsAsync();
    Task<ServiceResult<SegmentResponseDto>> GetSegmentByIdAsync(int segmentId);

    // ── Genres ────────────────────────────────────────────────────
    Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId);
    Task<ServiceResult<GenreResponseDto>> GetGenreByIdAsync(int genreId);

    // ── SubGenres ─────────────────────────────────────────────────
    Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId);

    // ── PriceZones ────────────────────────────────────────────────
    Task<ServiceResult<List<PriceZoneResponseDto>>> GetPriceZonesByVenueAsync(int venueId);
    Task<ServiceResult<PriceZoneResponseDto>> CreatePriceZoneAsync(CreatePriceZoneDto dto);

    // ── Bookmarks ─────────────────────────────────────────────────
    Task<ServiceResult<List<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId);
    Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId);
    Task<ServiceResult<bool>> DeleteBookmarkAsync(int bookmarkId, int userId);

    // ── Comments ──────────────────────────────────────────────────
    Task<ServiceResult<List<CommentResponseDto>>> GetEventCommentsAsync(int eventId);
    Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId);
    Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId);
    Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId);

}
