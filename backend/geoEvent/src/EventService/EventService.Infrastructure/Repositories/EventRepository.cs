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
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Venue)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<Event?> GetByIdWithDetailsAsync(int eventId) =>
        await _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Venue)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        var query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Venue)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .AsQueryable();

        if (filter.Status.HasValue)
            query = query.Where(e => e.Status == filter.Status.Value);

        if (filter.CityId.HasValue)
            query = query.Where(e => e.CityId == filter.CityId.Value);

        if (filter.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == filter.SegmentId.Value);

        if (filter.GenreId.HasValue)
            query = query.Where(e => e.GenreId == filter.GenreId.Value);

        if (filter.SubGenreId.HasValue)
            query = query.Where(e => e.SubGenreId == filter.SubGenreId.Value);

        if (filter.OrganizerId.HasValue)
            query = query.Where(e => e.OrganizerId == filter.OrganizerId.Value);

        if (filter.MinPrice.HasValue)
            query = query.Where(e => e.Price >= filter.MinPrice.Value);

        if (filter.MaxPrice.HasValue)
            query = query.Where(e => e.Price <= filter.MaxPrice.Value);

        if (filter.FromDate.HasValue)
            query = query.Where(e => e.StartDateTime >= filter.FromDate.Value);

        if (filter.ToDate.HasValue)
            query = query.Where(e => e.StartDateTime <= filter.ToDate.Value);

        if (filter.IsOnline.HasValue)
            query = query.Where(e => e.IsOnline == filter.IsOnline.Value);

        if (filter.IsFeatured.HasValue)
            query = query.Where(e => e.IsFeatured == filter.IsFeatured.Value);

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.Trim();

            query = query.Where(e =>
                e.Title.Contains(term) ||
                e.Description.Contains(term) ||
                (e.Tags != null && e.Tags.Contains(term)));
        }

        var sortBy = filter.SortBy?.Trim().ToLowerInvariant() ?? "startdatetime";

        query = sortBy switch
        {
            "price" => filter.SortDescending
                ? query.OrderByDescending(e => e.Price).ThenBy(e => e.EventId)
                : query.OrderBy(e => e.Price).ThenBy(e => e.EventId),

            "likescount" => filter.SortDescending
                ? query.OrderByDescending(e => e.LikesCount).ThenBy(e => e.EventId)
                : query.OrderBy(e => e.LikesCount).ThenBy(e => e.EventId),

            "viewcount" => filter.SortDescending
                ? query.OrderByDescending(e => e.ViewCount).ThenBy(e => e.EventId)
                : query.OrderBy(e => e.ViewCount).ThenBy(e => e.EventId),

            _ => filter.SortDescending
                ? query.OrderByDescending(e => e.StartDateTime).ThenByDescending(e => e.EventId)
                : query.OrderBy(e => e.StartDateTime).ThenBy(e => e.EventId),
        };

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 100);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Event>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<Event>> GetNearbyAsync(NearbyEventSearchDto dto)
    {
        var latitude = dto.Latitude!.Value;
        var longitude = dto.Longitude!.Value;

        var radiusKm = dto.RadiusKm <= 0 ? 50 : Math.Min(dto.RadiusKm, 500);
        var limit = dto.Limit <= 0 ? 20 : Math.Min(dto.Limit, 100);

        var latDelta = (decimal)(radiusKm / 111.0);

        var cosLatitude = Math.Cos((double)latitude * Math.PI / 180.0);
        if (Math.Abs(cosLatitude) < 0.000001)
            cosLatitude = 0.000001;

        var lonDelta = (decimal)(radiusKm / 111.0 / Math.Abs(cosLatitude));

        IQueryable<Event> query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Venue)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .Where(e =>
                e.Status == EventStatus.Active &&
                e.Latitude >= latitude - latDelta &&
                e.Latitude <= latitude + latDelta &&
                e.Longitude >= longitude - lonDelta &&
                e.Longitude <= longitude + lonDelta);

        if (dto.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == dto.SegmentId.Value);

        if (dto.GenreId.HasValue)
            query = query.Where(e => e.GenreId == dto.GenreId.Value);

        if (dto.SubGenreId.HasValue)
            query = query.Where(e => e.SubGenreId == dto.SubGenreId.Value);

        if (dto.MinPrice.HasValue)
            query = query.Where(e => e.Price >= dto.MinPrice.Value);

        if (dto.MaxPrice.HasValue)
            query = query.Where(e => e.Price <= dto.MaxPrice.Value);

        if (dto.TodayOnly)
        {
            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            query = query.Where(e =>
                e.StartDateTime >= today &&
                e.StartDateTime < tomorrow);
        }

        return await query
            .OrderBy(e => e.StartDateTime)
            .ThenBy(e => e.EventId)
            .Take(limit)
            .ToListAsync();
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

    public async Task IncrementViewCountAsync(int eventId)
    {
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.ViewCount, e => e.ViewCount + 1));
    }

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

        await _context.SaveChangesAsync();

        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.LikesCount, e => e.LikesCount + 1));
    }

    public async Task UnlikeAsync(int eventId, int userId)
    {
        var deletedRows = await _context.EventLikes
            .Where(l => l.EventId == eventId && l.UserId == userId)
            .ExecuteDeleteAsync();

        if (deletedRows > 0)
        {
            await _context.Events
                .Where(e => e.EventId == eventId && e.LikesCount > 0)
                .ExecuteUpdateAsync(s =>
                    s.SetProperty(e => e.LikesCount, e => e.LikesCount - 1));
        }
    }

    public async Task AddImageAsync(EventImage image)
    {
        image.UploadedAt = DateTime.UtcNow;
        await _context.EventImages.AddAsync(image);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteImageAsync(int imageId)
    {
        await _context.EventImages
            .Where(i => i.ImageId == imageId)
            .ExecuteDeleteAsync();
    }

    public async Task<EventImage?> GetImageAsync(int imageId) =>
        await _context.EventImages
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.ImageId == imageId);

    public async Task<List<EventImage>> GetEventImagesAsync(int eventId) =>
        await _context.EventImages
            .AsNoTracking()
            .Where(i => i.EventId == eventId)
            .OrderByDescending(i => i.IsCover)
            .ThenBy(i => i.UploadedAt)
            .ThenBy(i => i.ImageId)
            .ToListAsync();

    public async Task SetCoverImageAsync(int eventId, int imageId)
    {
        await _context.EventImages
            .Where(i => i.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(i => i.IsCover, false));

        await _context.EventImages
            .Where(i => i.EventId == eventId && i.ImageId == imageId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(i => i.IsCover, true));
    }

    public async Task<List<Segment>> GetAllSegmentsAsync() =>
        await _context.Segments
            .AsNoTracking()
            .Include(s => s.Genres)
            .ThenInclude(g => g.SubGenres)
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<Segment?> GetSegmentByIdAsync(int segmentId) =>
        await _context.Segments
            .AsNoTracking()
            .Include(s => s.Genres)
            .ThenInclude(g => g.SubGenres)
            .FirstOrDefaultAsync(s => s.SegmentId == segmentId);

    public async Task<List<Genre>> GetGenresBySegmentAsync(int segmentId) =>
        await _context.Genres
            .AsNoTracking()
            .Include(g => g.SubGenres)
            .Where(g => g.SegmentId == segmentId && g.IsActive)
            .OrderBy(g => g.Name)
            .ToListAsync();

    public async Task<Genre?> GetGenreByIdAsync(int genreId) =>
        await _context.Genres
            .AsNoTracking()
            .Include(g => g.SubGenres)
            .FirstOrDefaultAsync(g => g.GenreId == genreId);

    public async Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId) =>
        await _context.SubGenres
            .AsNoTracking()
            .Where(s => s.GenreId == genreId && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId) =>
        await _context.SubGenres
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SubGenreId == subGenreId);

    public async Task<Venue?> GetVenueByIdAsync(int venueId) =>
        await _context.Venues
            .AsNoTracking()
            .Include(v => v.PriceZones.Where(p => p.IsActive))
            .FirstOrDefaultAsync(v => v.VenueId == venueId);

    public async Task<List<Venue>> GetVenuesByCityAsync(int cityId) =>
        await _context.Venues
            .AsNoTracking()
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

    public async Task<List<PriceZone>> GetPriceZonesByVenueAsync(int venueId) =>
        await _context.PriceZones
            .AsNoTracking()
            .Where(p => p.VenueId == venueId && p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();

    public async Task<PriceZone?> GetPriceZoneByIdAsync(int priceZoneId) =>
        await _context.PriceZones
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PriceZoneId == priceZoneId);

    public async Task<PriceZone> CreatePriceZoneAsync(PriceZone priceZone)
    {
        _context.PriceZones.Add(priceZone);
        await _context.SaveChangesAsync();
        return priceZone;
    }

    public async Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId) =>
        await _context.Bookmarks
            .AsNoTracking()
            .Include(b => b.Event)
            .FirstOrDefaultAsync(b => b.BookmarkId == bookmarkId);

    public async Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId) =>
        await _context.Bookmarks
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.UserId == userId && b.EventId == eventId);

    public async Task<List<Bookmark>> GetUserBookmarksAsync(int userId) =>
        await _context.Bookmarks
            .AsNoTracking()
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

    public async Task UpdateBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Update(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task<Comment?> GetCommentByIdAsync(int commentId) =>
        await _context.Comments
            .Include(c => c.Replies)
            .FirstOrDefaultAsync(c => c.CommentId == commentId);

    public async Task<List<Comment>> GetEventCommentsAsync(int eventId) =>
        await _context.Comments
            .AsNoTracking()
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
            .AsNoTracking()
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

        await _context.SaveChangesAsync();

        await _context.Comments
            .Where(c => c.CommentId == commentId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(c => c.LikesCount, c => c.LikesCount + 1));
    }

    public async Task UnlikeCommentAsync(int commentId, int userId)
    {
        var deletedRows = await _context.CommentLikes
            .Where(l => l.CommentId == commentId && l.UserId == userId)
            .ExecuteDeleteAsync();

        if (deletedRows > 0)
        {
            await _context.Comments
                .Where(c => c.CommentId == commentId && c.LikesCount > 0)
                .ExecuteUpdateAsync(s =>
                    s.SetProperty(c => c.LikesCount, c => c.LikesCount - 1));
        }
    }
}