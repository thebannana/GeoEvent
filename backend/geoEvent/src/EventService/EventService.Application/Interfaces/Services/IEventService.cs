using EventService.Application.Common;
using EventService.Application.DTOs;

namespace EventService.Application.Interfaces.Services;

public interface IEventService
{
    // ── Events ────────────────────────────────────────────────
    Task<ServiceResult<EventResponseDto>> GetByIdAsync(int eventId);
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter);
    Task<ServiceResult<List<EventResponseDto>>> GetNearbyAsync(NearbyEventSearchDto dto);  // new
    Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId);
    Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId);
    Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> PostponeAsync(int eventId, int requesterId);              // new
    Task<ServiceResult<bool>> CompleteAsync(int eventId, int requesterId);              // new

    // ── Likes ─────────────────────────────────────────────────
    Task<ServiceResult<bool>> LikeAsync(int eventId, int userId);
    Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId);

    // ── Images ────────────────────────────────────────────────
    Task<ServiceResult<bool>> AddImageAsync(int eventId, string imageUrl, bool isCover, int requesterId);  // add requesterId
    Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId);          // new
    Task<ServiceResult<bool>> SetCoverImageAsync(int eventId, int imageId, int requesterId); // new

    // ── Segments ──────────────────────────────────────────────
    Task<ServiceResult<List<SegmentResponseDto>>> GetAllSegmentsAsync();
    Task<ServiceResult<SegmentResponseDto>> GetSegmentByIdAsync(int segmentId);

    // ── Genres ────────────────────────────────────────────────
    Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId);
    Task<ServiceResult<GenreResponseDto>> GetGenreByIdAsync(int genreId);

    // ── SubGenres ─────────────────────────────────────────────
    Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId);

    // ── Venues ────────────────────────────────────────────────
    Task<ServiceResult<VenueResponseDto>> GetVenueByIdAsync(int venueId);              // new
    Task<ServiceResult<List<VenueResponseDto>>> GetVenuesByCityAsync(int cityId);      // new
    Task<ServiceResult<VenueResponseDto>> CreateVenueAsync(CreateVenueDto dto);        // new

    // ── PriceZones ────────────────────────────────────────────
    Task<ServiceResult<List<PriceZoneResponseDto>>> GetPriceZonesByVenueAsync(int venueId);
    Task<ServiceResult<PriceZoneResponseDto>> CreatePriceZoneAsync(CreatePriceZoneDto dto, int requesterId); // add requesterId

    // ── Bookmarks ─────────────────────────────────────────────
    Task<ServiceResult<List<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId);
    Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId);
    Task<ServiceResult<BookmarkResponseDto>> UpdateBookmarkAsync(int bookmarkId, UpdateBookmarkDto dto, int userId); // new
    Task<ServiceResult<bool>> DeleteBookmarkAsync(int bookmarkId, int userId);

    // ── Comments ──────────────────────────────────────────────
    Task<ServiceResult<List<CommentResponseDto>>> GetEventCommentsAsync(int eventId);
    Task<ServiceResult<List<CommentResponseDto>>> GetRepliesAsync(int commentId);      // new
    Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId);
    Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId);
    Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId);
    Task<ServiceResult<bool>> LikeCommentAsync(int commentId, int userId);             // new
    Task<ServiceResult<bool>> UnlikeCommentAsync(int commentId, int userId);           // new
}
