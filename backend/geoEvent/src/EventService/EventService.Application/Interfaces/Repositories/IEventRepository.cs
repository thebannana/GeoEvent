using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Domain.Entities;

namespace EventService.Application.Interfaces.Repositories;

public interface IEventRepository
{
    Task<Event?> GetByIdAsync(int eventId);
    Task<Event?> GetByIdWithImagesAsync(int eventId);
    Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter);
    Task<Event> CreateAsync(Event entity);
    Task UpdateAsync(Event entity);
    Task DeleteAsync(int eventId);
    Task<bool> ExistsAsync(int eventId);
    Task IncrementViewCountAsync(int eventId);

    // Likes
    Task<bool> IsLikedByUserAsync(int eventId, int userId);
    Task LikeAsync(int eventId, int userId);
    Task UnlikeAsync(int eventId, int userId);

    // Images
    Task AddImageAsync(EventImage image);
    Task DeleteImageAsync(int imageId);
    Task<EventImage?> GetImageAsync(int imageId);

    // ── Segments ──────────────────────────────────────────────────
    Task<List<Segment>> GetAllSegmentsAsync();
    Task<Segment?> GetSegmentByIdAsync(int segmentId);

    // ── Genres ────────────────────────────────────────────────────
    Task<List<Genre>> GetGenresBySegmentAsync(int segmentId);
    Task<Genre?> GetGenreByIdAsync(int genreId);

    // ── SubGenres ─────────────────────────────────────────────────
    Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId);

    // ── PriceZones ────────────────────────────────────────────────
    Task<List<PriceZone>> GetPriceZonesByVenueAsync(int venueId);
    Task<PriceZone?> GetPriceZoneByIdAsync(int priceZoneId);
    Task<PriceZone> CreatePriceZoneAsync(PriceZone priceZone);

    // ── Bookmarks ─────────────────────────────────────────────────
    Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId);
    Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId);
    Task<List<Bookmark>> GetUserBookmarksAsync(int userId);
    Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark);
    Task DeleteBookmarkAsync(Bookmark bookmark);

    // ── Comments ──────────────────────────────────────────────────
    Task<Comment?> GetCommentByIdAsync(int commentId);
    Task<List<Comment>> GetEventCommentsAsync(int eventId);
    Task<Comment> CreateCommentAsync(Comment comment);
    Task UpdateCommentAsync(Comment comment);

}
