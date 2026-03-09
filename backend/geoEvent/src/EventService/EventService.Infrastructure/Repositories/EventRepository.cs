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
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<Event?> GetByIdWithImagesAsync(int eventId) =>
        await _context.Events
            .Include(e => e.Images)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter)
    {
        var query = _context.Events
            .Include(e => e.Images)
            .AsQueryable();

        if (filter.CityId.HasValue)
            query = query.Where(e => e.CityId == filter.CityId);
        if (filter.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == filter.SegmentId);
        if (filter.GenreId.HasValue)
            query = query.Where(e => e.GenreId == filter.GenreId);
        if (filter.OrganizerId.HasValue)
            query = query.Where(e => e.OrganizerId == filter.OrganizerId);
        if (filter.MinPrice.HasValue)
            query = query.Where(e => e.Price >= filter.MinPrice);
        if (filter.MaxPrice.HasValue)
            query = query.Where(e => e.Price <= filter.MaxPrice);
        if (filter.FromDate.HasValue)
            query = query.Where(e => e.StartDateTime >= filter.FromDate);
        if (filter.ToDate.HasValue)
            query = query.Where(e => e.StartDateTime <= filter.ToDate);
        if (filter.IsOnline.HasValue)
            query = query.Where(e => e.IsOnline == filter.IsOnline);
        if (filter.IsFeatured.HasValue)
            query = query.Where(e => e.IsFeatured == filter.IsFeatured);
        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            query = query.Where(e =>
                e.Title.Contains(filter.SearchTerm) ||
                e.Description.Contains(filter.SearchTerm) ||
                e.Tags!.Contains(filter.SearchTerm));
        if (!string.IsNullOrWhiteSpace(filter.Status) &&
            Enum.TryParse<EventStatus>(filter.Status, out var status))
            query = query.Where(e => e.Status == status);

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

    public async Task<bool> IsLikedByUserAsync(int eventId, int userId) =>
        await _context.EventLikes
            .AnyAsync(l => l.EventId == eventId && l.UserId == userId);

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

}
