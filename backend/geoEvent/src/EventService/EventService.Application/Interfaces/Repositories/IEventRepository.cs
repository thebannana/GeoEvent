using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Domain.Entities;

namespace EventService.Application.Interfaces.Repositories;

public interface IEventRepository
{
    // ── Events ────────────────────────────────────────────────
    Task<Event?> GetByIdAsync(int eventId);
    Task<Event?> GetByIdWithDetailsAsync(int eventId);
    Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter);
    Task<List<Event>> GetNearbyAsync(NearbyEventSearchDto dto);
    Task<Event> CreateAsync(Event entity);
    Task UpdateAsync(Event entity);
    Task DeleteAsync(int eventId);
    Task<bool> ExistsAsync(int eventId);
    Task IncrementViewCountAsync(int eventId);

    // ── Likes ─────────────────────────────────────────────────
    Task<bool> IsLikedByUserAsync(int eventId, int userId);
    Task LikeAsync(int eventId, int userId);
    Task UnlikeAsync(int eventId, int userId);

    // ── Images ────────────────────────────────────────────────
    Task AddImageAsync(EventImage image);
    Task DeleteImageAsync(int imageId);
    Task<EventImage?> GetImageAsync(int imageId);
    Task<List<EventImage>> GetEventImagesAsync(int eventId);
    Task SetCoverImageAsync(int eventId, int imageId);

    // ── Segments ──────────────────────────────────────────────
    Task<List<Segment>> GetAllSegmentsAsync();
    Task<Segment?> GetSegmentByIdAsync(int segmentId);

    // ── Genres ────────────────────────────────────────────────
    Task<List<Genre>> GetGenresBySegmentAsync(int segmentId);
    Task<Genre?> GetGenreByIdAsync(int genreId);

    // ── SubGenres ─────────────────────────────────────────────
    Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId);
    Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId);

    // ── Venues ────────────────────────────────────────────────
    Task<Venue?> GetVenueByIdAsync(int venueId);
    Task<List<Venue>> GetVenuesByCityAsync(int cityId);
    Task<Venue> CreateVenueAsync(Venue venue);

    // ── PriceZones ────────────────────────────────────────────
    Task<List<PriceZone>> GetPriceZonesByVenueAsync(int venueId);
    Task<PriceZone?> GetPriceZoneByIdAsync(int priceZoneId);
    Task<PriceZone> CreatePriceZoneAsync(PriceZone priceZone);

    // ── Bookmarks ─────────────────────────────────────────────
    Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId);
    Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId);
    Task<List<Bookmark>> GetUserBookmarksAsync(int userId);
    Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark);
    Task UpdateBookmarkAsync(Bookmark bookmark);
    Task DeleteBookmarkAsync(Bookmark bookmark);

    // ── Comments ──────────────────────────────────────────────
    Task<Comment?> GetCommentByIdAsync(int commentId);
    Task<List<Comment>> GetEventCommentsAsync(int eventId);
    Task<Comment> CreateCommentAsync(Comment comment);
    Task UpdateCommentAsync(Comment comment);
    Task<List<Comment>> GetRepliesAsync(int parentCommentId);
    Task<bool> IsCommentLikedByUserAsync(int commentId, int userId);
    Task LikeCommentAsync(int commentId, int userId);
    Task UnlikeCommentAsync(int commentId, int userId);
}