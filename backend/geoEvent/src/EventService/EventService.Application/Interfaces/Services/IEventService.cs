using EventService.Application.Common;
using EventService.Application.DTOs;

namespace EventService.Application.Interfaces.Services;

public interface IEventService
{
    // ── Public events ─────────────────────────────────────────
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetPublicAsync(EventFilterDto filter, int? requesterId = null);
    Task<ServiceResult<EventResponseDto>> GetPublicByIdAsync(int eventId, int? requesterId = null);
    Task<ServiceResult<List<EventResponseDto>>> GetNearbyPublicAsync(NearbyEventSearchDto dto);
    Task<ServiceResult<List<LikedEventResponseDto>>> GetLikedEventsAsync(int userId);

    // ── Organizer/private events ─────────────────────────────
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetMyDraftsAsync(EventFilterDto filter, int requesterId);
    Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId);
    Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId);
    Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId, string reason = "Cancelled by organizer");
    Task<ServiceResult<bool>> PostponeAsync(int eventId, int requesterId);
    Task<ServiceResult<bool>> CompleteAsync(int eventId, int requesterId);
    Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter);

    // ── Interactions ─────────────────────────────────────────
    Task<ServiceResult<bool>> LikeAsync(int eventId, int userId);
    Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId);

    // ── Images ────────────────────────────────────────────────
    Task<ServiceResult<bool>> AddImageAsync(int eventId, string imageUrl, bool isCover, int requesterId);
    Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId);
    Task<ServiceResult<bool>> SetCoverImageAsync(int eventId, int imageId, int requesterId);

    // ── Segments ──────────────────────────────────────────────
    // Segments
    Task<ServiceResult<List<SegmentResponseDto>>> GetAllSegmentsAsync();
    Task<ServiceResult<SegmentResponseDto>> GetSegmentByIdAsync(int segmentId);
    Task<ServiceResult<SegmentResponseDto>> CreateSegmentAsync(CreateSegmentDto dto);
    Task<ServiceResult<SegmentResponseDto>> UpdateSegmentAsync(int segmentId, UpdateSegmentDto dto);

    // Genres
    Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId);
    Task<ServiceResult<GenreResponseDto>> GetGenreByIdAsync(int genreId);
    Task<ServiceResult<GenreResponseDto>> CreateGenreAsync(CreateGenreDto dto);
    Task<ServiceResult<GenreResponseDto>> UpdateGenreAsync(int genreId, UpdateGenreDto dto);
    // SubGenres
    Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId);
    Task<ServiceResult<SubGenreResponseDto>> GetSubGenreByIdAsync(int subGenreId);
    Task<ServiceResult<SubGenreResponseDto>> CreateSubGenreAsync(CreateSubGenreDto dto);
    Task<ServiceResult<SubGenreResponseDto>> UpdateSubGenreAsync(int subGenreId, UpdateSubGenreDto dto);

    // ── Venues ────────────────────────────────────────────────
    Task<ServiceResult<VenueResponseDto>> GetVenueByIdAsync(int venueId);
    Task<ServiceResult<List<VenueResponseDto>>> GetVenuesByCityAsync(int cityId);
    Task<ServiceResult<VenueResponseDto>> CreateVenueAsync(CreateVenueDto dto);

    // ── PriceZones ────────────────────────────────────────────
    Task<ServiceResult<List<PriceZoneResponseDto>>> GetPriceZonesByVenueAsync(int venueId);
    Task<ServiceResult<PriceZoneResponseDto>> CreatePriceZoneAsync(CreatePriceZoneDto dto, int requesterId);

    // ── Bookmarks ─────────────────────────────────────────────
    Task<ServiceResult<List<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId);
    Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId);
    Task<ServiceResult<BookmarkResponseDto>> UpdateBookmarkAsync(int bookmarkId, UpdateBookmarkDto dto, int userId);
    Task<ServiceResult<bool>> DeleteBookmarkAsync(int bookmarkId, int userId);

    // ── Comments ──────────────────────────────────────────────
    Task<ServiceResult<CommentResponseDto>> GetCommentByIdAsync(int commentId, int? requesterId = null);
    Task<ServiceResult<List<CommentResponseDto>>> GetEventCommentsAsync(int eventId, int? requesterId = null);
    Task<ServiceResult<List<CommentResponseDto>>> GetRepliesAsync(int commentId, int? requesterId = null);
    Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId);
    Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId);
    Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId);
    Task<ServiceResult<bool>> LikeCommentAsync(int commentId, int userId);
    Task<ServiceResult<bool>> UnlikeCommentAsync(int commentId, int userId);
}