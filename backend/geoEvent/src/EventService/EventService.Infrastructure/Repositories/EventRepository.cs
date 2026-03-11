using Microsoft.EntityFrameworkCore;
using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Domain.Entities;
using EventService.Domain.Enums;
using EventService.Infrastructure.Persistence;

namespace EventService.Infrastructure.Repositories;

public class EventRepository : IEventRepository
{
    private readonly EventDbContext _context;

    public EventRepository(EventDbContext context)
    {
        _context = context;
    }

    public async Task<Event?> GetByIdAsync(int eventId) =>
    await _context.Events
        .Include(e => e.Images)
        .Include(e => e.Venue)
        .Include(e => e.Segment)
        .Include(e => e.Genre)
        .Include(e => e.SubGenre)
        .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<Event?> GetByIdWithDetailsAsync(int eventId) =>
    await _context.Events
        .Include(e => e.Images)
        .Include(e => e.Venue)
        .Include(e => e.Segment)
        .Include(e => e.Genre)
        .Include(e => e.SubGenre)
        .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter)
    {
        var query = _context.Events
            .Include(e => e.Images)
            .AsQueryable();

        if (filter.Status.HasValue)
            query = query.Where(e => e.Status == filter.Status.Value);

        var totalCount = await query.CountAsync();

        query = filter.SortBy.ToLower() switch
        {
            "price" => filter.SortDescending
                ? query.OrderByDescending(e => e.Price)
                : query.OrderBy(e => e.Price),
            "likescount" => filter.SortDescending
                ? query.OrderByDescending(e => e.LikesCount)
                : query.OrderBy(e => e.LikesCount),
            "viewcount" => filter.SortDescending
                ? query.OrderByDescending(e => e.ViewCount)
                : query.OrderBy(e => e.ViewCount),
            _ => filter.SortDescending
                ? query.OrderByDescending(e => e.StartDateTime)
                : query.OrderBy(e => e.StartDateTime)
        };

        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Event>
        {
            Items = items,
            TotalCount = totalCount,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<List<Event>> GetNearbyAsync(NearbyEventSearchDto dto)
    {
        // Degree approximations for bounding box pre-filter
        var latDelta = (decimal)(dto.RadiusKm / 111.0);
        var lonDelta = (decimal)(dto.RadiusKm / (111.0 * Math.Cos((double)dto.Latitude * Math.PI / 180.0)));

        return await _context.Events
            .Include(e => e.Images)
            .Include(e => e.Venue)
            .Where(e => e.Status == EventStatus.Active &&
                        e.Latitude >= dto.Latitude - latDelta &&
                        e.Latitude <= dto.Latitude + latDelta &&
                        e.Longitude >= dto.Longitude - lonDelta &&
                        e.Longitude <= dto.Longitude + lonDelta)
            .OrderBy(e => e.StartDateTime)
            .Take(dto.Limit)
            .ToListAsync();
    }

    public async Task<List<EventImage>> GetEventImagesAsync(int eventId) =>
    await _context.EventImages
        .Where(i => i.EventId == eventId)
        .OrderByDescending(i => i.IsCover)
        .ThenBy(i => i.UploadedAt)
        .ToListAsync();

    public async Task SetCoverImageAsync(int eventId, int imageId)
    {
        await _context.EventImages
            .Where(i => i.EventId == eventId)
            .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, false));

        await _context.EventImages
            .Where(i => i.ImageId == imageId)
            .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, true));
    }


    public async Task<Event> CreateAsync(Event entity)
    {
        entity.CreatedAt = DateTime.UtcNow;
        await _context.Events.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task UpdateAsync(Event entity)
    {
        entity.UpdatedAt = DateTime.UtcNow;
        _context.Events.Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(int eventId)
    {
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteDeleteAsync();
    }

    public async Task<bool> ExistsAsync(int eventId) =>
        await _context.Events.AnyAsync(e => e.EventId == eventId);

    public async Task IncrementViewCountAsync(int eventId) =>
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.ViewCount, e => e.ViewCount + 1));

    public async Task LikeAsync(int eventId, int userId)
    {
        await _context.EventLikes.AddAsync(new EventLike
        {
            EventId = eventId,
            UserId = userId,
            LikedAt = DateTime.UtcNow
        });
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.LikesCount, e => e.LikesCount + 1));
    }

    public async Task<bool> IsLikedByUserAsync(int eventId, int userId) =>
    await _context.EventLikes
        .AnyAsync(l => l.EventId == eventId && l.UserId == userId);


    public async Task UnlikeAsync(int eventId, int userId)
    {
        await _context.EventLikes
            .Where(l => l.EventId == eventId && l.UserId == userId)
            .ExecuteDeleteAsync();
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.LikesCount, e => e.LikesCount - 1));
    }

    public async Task AddImageAsync(EventImage image)
    {
        image.UploadedAt = DateTime.UtcNow;
        await _context.EventImages.AddAsync(image);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteImageAsync(int imageId) =>
        await _context.EventImages
            .Where(i => i.ImageId == imageId)
            .ExecuteDeleteAsync();

    public async Task<EventImage?> GetImageAsync(int imageId) =>
        await _context.EventImages.FindAsync(imageId);

    // ── Segments ──────────────────────────────────────────────────
    public async Task<List<Segment>> GetAllSegmentsAsync() =>
        await _context.Segments
            .Include(s => s.Genres)
            .ThenInclude(g => g.SubGenres)
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<Segment?> GetSegmentByIdAsync(int segmentId) =>
        await _context.Segments
            .Include(s => s.Genres)
            .ThenInclude(g => g.SubGenres)
            .FirstOrDefaultAsync(s => s.SegmentId == segmentId);

    // ── Genres ────────────────────────────────────────────────────
    public async Task<List<Genre>> GetGenresBySegmentAsync(int segmentId) =>
        await _context.Genres
            .Include(g => g.SubGenres)
            .Where(g => g.SegmentId == segmentId && g.IsActive)
            .OrderBy(g => g.Name)
            .ToListAsync();

    public async Task<Genre?> GetGenreByIdAsync(int genreId) =>
        await _context.Genres
            .Include(g => g.SubGenres)
            .FirstOrDefaultAsync(g => g.GenreId == genreId);

    // ── SubGenres ─────────────────────────────────────────────────
    public async Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId) =>
        await _context.SubGenres
            .Where(s => s.GenreId == genreId && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId) =>
    await _context.SubGenres.FindAsync(subGenreId);


    // ── PriceZones ────────────────────────────────────────────────
    public async Task<List<PriceZone>> GetPriceZonesByVenueAsync(int venueId) =>
        await _context.PriceZones
            .Where(p => p.VenueId == venueId && p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();

    public async Task<PriceZone?> GetPriceZoneByIdAsync(int priceZoneId) =>
        await _context.PriceZones
            .FirstOrDefaultAsync(p => p.PriceZoneId == priceZoneId);

    public async Task<PriceZone> CreatePriceZoneAsync(PriceZone priceZone)
    {
        _context.PriceZones.Add(priceZone);
        await _context.SaveChangesAsync();
        return priceZone;
    }

    // ── Bookmarks ─────────────────────────────────────────────────
    public async Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId) =>
        await _context.Bookmarks
            .Include(b => b.Event)
            .FirstOrDefaultAsync(b => b.BookmarkId == bookmarkId);

    public async Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId) =>
        await _context.Bookmarks
            .FirstOrDefaultAsync(b => b.UserId == userId && b.EventId == eventId);

    public async Task<List<Bookmark>> GetUserBookmarksAsync(int userId) =>
        await _context.Bookmarks
            .Include(b => b.Event)
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.SavedAt)
            .ToListAsync();

    public async Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Add(bookmark);
        await _context.SaveChangesAsync();
        return bookmark;
    }

    public async Task DeleteBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Update(bookmark);
        await _context.SaveChangesAsync();
    }


    // ── Comments ──────────────────────────────────────────────────
    public async Task<Comment?> GetCommentByIdAsync(int commentId) =>
        await _context.Comments
            .Include(c => c.Replies)
            .FirstOrDefaultAsync(c => c.CommentId == commentId);

    public async Task<List<Comment>> GetEventCommentsAsync(int eventId) =>
        await _context.Comments
            .Include(c => c.Replies)
            .Where(c => c.EventId == eventId && c.ParentCommentId == null && !c.IsDeleted)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

    public async Task<Comment> CreateCommentAsync(Comment comment)
    {
        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();
        return comment;
    }

    public async Task UpdateCommentAsync(Comment comment)
    {
        _context.Comments.Update(comment);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Comment>> GetRepliesAsync(int parentCommentId) =>
    await _context.Comments
        .Where(c => c.ParentCommentId == parentCommentId && !c.IsDeleted)
        .OrderBy(c => c.CreatedAt)
        .ToListAsync();

    public async Task<bool> IsCommentLikedByUserAsync(int commentId, int userId) =>
        await _context.CommentLikes
            .AnyAsync(l => l.CommentId == commentId && l.UserId == userId);

    public async Task LikeCommentAsync(int commentId, int userId)
    {
        _context.CommentLikes.Add(new CommentLike
        {
            CommentId = commentId,
            UserId = userId,
            LikedAt = DateTime.UtcNow
        });
        await _context.Comments
            .Where(c => c.CommentId == commentId)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.LikesCount, c => c.LikesCount + 1));
        await _context.SaveChangesAsync();
    }

    public async Task UnlikeCommentAsync(int commentId, int userId)
    {
        await _context.CommentLikes
            .Where(l => l.CommentId == commentId && l.UserId == userId)
            .ExecuteDeleteAsync();
        await _context.Comments
            .Where(c => c.CommentId == commentId && c.LikesCount > 0)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.LikesCount, c => c.LikesCount - 1));
    }


    // ── Venues ─────────────────────────────────────────────────

    public async Task<Venue?> GetVenueByIdAsync(int venueId) =>
    await _context.Venues
        .Include(v => v.PriceZones.Where(p => p.IsActive))
        .FirstOrDefaultAsync(v => v.VenueId == venueId);

    public async Task<List<Venue>> GetVenuesByCityAsync(int cityId) =>
        await _context.Venues
            .Where(v => v.CityId == cityId)
            .OrderBy(v => v.Name)
            .ToListAsync();

    public async Task<Venue> CreateVenueAsync(Venue venue)
    {
        venue.CreatedAt = DateTime.UtcNow;
        _context.Venues.Add(venue);
        await _context.SaveChangesAsync();
        return venue;
    }

}
