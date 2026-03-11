using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Domain.Entities;

namespace EventService.Application.Interfaces.Repositories;

public interface IEventRepository
{
    // ── Events ────────────────────────────────────────────────
    Task<Event?> GetByIdAsync(int eventId);
    Task<Event?> GetByIdWithDetailsAsync(int eventId);        // rename — includes venue, segment, genre, images
    Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter);
    Task<List<Event>> GetNearbyAsync(NearbyEventSearchDto dto); // new — geo search
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
    Task<List<EventImage>> GetEventImagesAsync(int eventId);   // new
    Task SetCoverImageAsync(int eventId, int imageId);         // new

    // ── Segments ──────────────────────────────────────────────
    Task<List<Segment>> GetAllSegmentsAsync();
    Task<Segment?> GetSegmentByIdAsync(int segmentId);

    // ── Genres ────────────────────────────────────────────────
    Task<List<Genre>> GetGenresBySegmentAsync(int segmentId);
    Task<Genre?> GetGenreByIdAsync(int genreId);

    // ── SubGenres ─────────────────────────────────────────────
    Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId);
    Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId);       // new

    // ── Venues ────────────────────────────────────────────────
    Task<Venue?> GetVenueByIdAsync(int venueId);               // new
    Task<List<Venue>> GetVenuesByCityAsync(int cityId);        // new
    Task<Venue> CreateVenueAsync(Venue venue);                 // new

    // ── PriceZones ────────────────────────────────────────────
    Task<List<PriceZone>> GetPriceZonesByVenueAsync(int venueId);
    Task<PriceZone?> GetPriceZoneByIdAsync(int priceZoneId);
    Task<PriceZone> CreatePriceZoneAsync(PriceZone priceZone);

    // ── Bookmarks ─────────────────────────────────────────────
    Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId);
    Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId);
    Task<List<Bookmark>> GetUserBookmarksAsync(int userId);
    Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark);
    Task UpdateBookmarkAsync(Bookmark bookmark);               // new — for memo edits
    Task DeleteBookmarkAsync(Bookmark bookmark);

    // ── Comments ──────────────────────────────────────────────
    Task<Comment?> GetCommentByIdAsync(int commentId);
    Task<List<Comment>> GetEventCommentsAsync(int eventId);
    Task<Comment> CreateCommentAsync(Comment comment);
    Task UpdateCommentAsync(Comment comment);
    Task<List<Comment>> GetRepliesAsync(int parentCommentId);  // new — load replies on demand
    Task<bool> IsCommentLikedByUserAsync(int commentId, int userId);  // new — comment like dedup
    Task LikeCommentAsync(int commentId, int userId);          // new
    Task UnlikeCommentAsync(int commentId, int userId);        // new
}
